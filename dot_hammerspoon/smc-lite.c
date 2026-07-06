#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define KERNEL_INDEX_SMC 2
#define SMC_CMD_READ_BYTES 5
#define SMC_CMD_WRITE_BYTES 6
#define SMC_CMD_READ_KEYINFO 9

typedef struct {
    uint8_t major;
    uint8_t minor;
    uint8_t build;
    uint8_t reserved;
    uint16_t release;
} SMCVersion;

typedef struct {
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
} SMCPLimitData;

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    uint8_t dataAttributes;
} SMCKeyInfoData;

typedef struct {
    uint32_t key;
    SMCVersion vers;
    SMCPLimitData pLimitData;
    SMCKeyInfoData keyInfo;
    uint8_t result;
    uint8_t status;
    uint8_t data8;
    uint32_t data32;
    uint8_t bytes[32];
} SMCParam;

static uint32_t smc_key_from_string(const char *s) {
    return ((uint32_t)(uint8_t)s[0] << 24) |
           ((uint32_t)(uint8_t)s[1] << 16) |
           ((uint32_t)(uint8_t)s[2] << 8) |
           ((uint32_t)(uint8_t)s[3]);
}

static void smc_key_to_string(uint32_t key, char out[5]) {
    out[0] = (char)(key >> 24);
    out[1] = (char)(key >> 16);
    out[2] = (char)(key >> 8);
    out[3] = (char)key;
    out[4] = '\0';
}

static int hex_nibble(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static int parse_hex(const char *hex, uint8_t *bytes, size_t expected_len) {
    size_t hex_len = strlen(hex);
    if (hex_len != expected_len * 2) return -1;

    for (size_t i = 0; i < expected_len; i++) {
        int hi = hex_nibble(hex[i * 2]);
        int lo = hex_nibble(hex[i * 2 + 1]);
        if (hi < 0 || lo < 0) return -1;
        bytes[i] = (uint8_t)((hi << 4) | lo);
    }
    return 0;
}

static void print_hex(const uint8_t *bytes, size_t len) {
    for (size_t i = 0; i < len; i++) printf("%02X", bytes[i]);
}

static kern_return_t smc_open(io_connect_t *conn) {
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (!service) return kIOReturnNotFound;

    kern_return_t ret = IOServiceOpen(service, mach_task_self(), 0, conn);
    IOObjectRelease(service);
    return ret;
}

static kern_return_t smc_call(io_connect_t conn, SMCParam *input, SMCParam *output) {
    size_t input_size = sizeof(SMCParam);
    size_t output_size = sizeof(SMCParam);
    memset(output, 0, sizeof(*output));
    return IOConnectCallStructMethod(conn, KERNEL_INDEX_SMC, input, input_size, output, &output_size);
}

static kern_return_t smc_key_info(io_connect_t conn, const char *key, SMCKeyInfoData *info) {
    SMCParam input = {0};
    SMCParam output = {0};

    input.key = smc_key_from_string(key);
    input.data8 = SMC_CMD_READ_KEYINFO;

    kern_return_t ret = smc_call(conn, &input, &output);
    if (ret != kIOReturnSuccess) return ret;
    if (output.result != 0) return kIOReturnError;

    *info = output.keyInfo;
    return kIOReturnSuccess;
}

static kern_return_t smc_read(io_connect_t conn, const char *key, uint8_t *bytes, SMCKeyInfoData *info) {
    kern_return_t ret = smc_key_info(conn, key, info);
    if (ret != kIOReturnSuccess) return ret;
    if (info->dataSize > 32) return kIOReturnBadArgument;

    SMCParam input = {0};
    SMCParam output = {0};
    input.key = smc_key_from_string(key);
    input.keyInfo.dataSize = info->dataSize;
    input.data8 = SMC_CMD_READ_BYTES;

    ret = smc_call(conn, &input, &output);
    if (ret != kIOReturnSuccess) return ret;
    if (output.result != 0) return kIOReturnError;

    memcpy(bytes, output.bytes, info->dataSize);
    return kIOReturnSuccess;
}

static kern_return_t smc_write(io_connect_t conn, const char *key, const uint8_t *bytes, SMCKeyInfoData *info) {
    kern_return_t ret = smc_key_info(conn, key, info);
    if (ret != kIOReturnSuccess) return ret;
    if (info->dataSize > 32) return kIOReturnBadArgument;

    SMCParam input = {0};
    SMCParam output = {0};
    input.key = smc_key_from_string(key);
    input.keyInfo.dataSize = info->dataSize;
    input.data8 = SMC_CMD_WRITE_BYTES;
    memcpy(input.bytes, bytes, info->dataSize);

    ret = smc_call(conn, &input, &output);
    if (ret != kIOReturnSuccess) return ret;
    if (output.result != 0) return kIOReturnError;
    return kIOReturnSuccess;
}

static void print_info(const char *key, const SMCKeyInfoData *info) {
    char type[5];
    smc_key_to_string(info->dataType, type);
    printf("%s type=%s size=%u attributes=0x%02X", key, type, info->dataSize, info->dataAttributes);
}

static void usage(const char *prog) {
    fprintf(stderr,
            "Usage:\n"
            "  %s info KEY\n"
            "  %s read KEY\n"
            "  %s write KEY HEX\n"
            "\n"
            "Examples:\n"
            "  %s read LSOF\n"
            "  %s write LSOO 00\n",
            prog, prog, prog, prog, prog);
}

int main(int argc, char **argv) {
    if (argc < 3 || strlen(argv[2]) != 4) {
        usage(argv[0]);
        return 2;
    }

    const char *command = argv[1];
    const char *key = argv[2];
    io_connect_t conn = 0;
    kern_return_t ret = smc_open(&conn);
    if (ret != kIOReturnSuccess) {
        fprintf(stderr, "AppleSMC open failed: 0x%08x\n", ret);
        return 1;
    }

    SMCKeyInfoData info = {0};
    if (strcmp(command, "info") == 0) {
        ret = smc_key_info(conn, key, &info);
        if (ret == kIOReturnSuccess) {
            print_info(key, &info);
            printf("\n");
        }
    } else if (strcmp(command, "read") == 0) {
        uint8_t bytes[32] = {0};
        ret = smc_read(conn, key, bytes, &info);
        if (ret == kIOReturnSuccess) {
            print_info(key, &info);
            printf(" value=");
            print_hex(bytes, info.dataSize);
            printf("\n");
        }
    } else if (strcmp(command, "write") == 0) {
        if (argc != 4) {
            usage(argv[0]);
            IOServiceClose(conn);
            return 2;
        }

        ret = smc_key_info(conn, key, &info);
        if (ret == kIOReturnSuccess) {
            uint8_t bytes[32] = {0};
            if (parse_hex(argv[3], bytes, info.dataSize) != 0) {
                char type[5];
                smc_key_to_string(info.dataType, type);
                fprintf(stderr, "%s expects %u byte(s), type %s; provide exactly %u hex chars\n",
                        key, info.dataSize, type, info.dataSize * 2);
                IOServiceClose(conn);
                return 2;
            }
            ret = smc_write(conn, key, bytes, &info);
            if (ret == kIOReturnSuccess) {
                print_info(key, &info);
                printf(" wrote=");
                print_hex(bytes, info.dataSize);
                printf("\n");
            }
        }
    } else {
        usage(argv[0]);
        IOServiceClose(conn);
        return 2;
    }

    IOServiceClose(conn);
    if (ret != kIOReturnSuccess) {
        fprintf(stderr, "%s %s failed: 0x%08x\n", command, key, ret);
        return 1;
    }
    return 0;
}
