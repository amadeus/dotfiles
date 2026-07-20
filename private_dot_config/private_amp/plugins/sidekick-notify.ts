import type { PluginAPI } from "@ampcode/plugin"

export default function (amp: PluginAPI) {
  amp.on("agent.end", async (event) => {
    const nvim = process.env.NVIM
    if (!nvim || event.status !== "done" || amp.activeThread.current?.id !== event.thread.id) {
      return
    }

    try {
      await amp.$`nvim --server ${nvim} --remote-expr ${"execute('SidekickNotify amp waiting')"}`
    } catch {
      // Neovim may have exited while Amp is still running.
    }
  })
}
