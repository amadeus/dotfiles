local audio = hs.audiodevice
local watcher = hs.caffeinate.watcher

local smc = hs.configdir .. "/smc-lite"
local previousMute = {}

local function setStudioLight(behavior)
	hs.execute(string.format("sudo -n %q write LSSB %s", smc, behavior), true)
end

local function muteDevice(device)
	if not device then
		return
	end

	local uid = device:uid() or device:name()
	if uid and previousMute[uid] == nil then
		previousMute[uid] = device:muted()
	end

	device:setMuted(true)
end

local function restoreDevice(device)
	if not device then
		return
	end

	local uid = device:uid() or device:name()
	local wasMuted = uid and previousMute[uid]

	if wasMuted ~= nil then
		device:setMuted(wasMuted)
		previousMute[uid] = nil
	end
end

displayMuteWatcher = watcher
	.new(function(event)
		if event == watcher.screensDidSleep or event == watcher.systemWillSleep then
			setStudioLight("0201")
			muteDevice(audio.defaultOutputDevice())
			muteDevice(audio.defaultEffectDevice())
		elseif event == watcher.screensDidWake or event == watcher.systemDidWake then
			setStudioLight("0101")
			restoreDevice(audio.defaultOutputDevice())
			restoreDevice(audio.defaultEffectDevice())
		end
	end)
	:start()
