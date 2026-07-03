local audio = hs.audiodevice
local watcher = hs.caffeinate.watcher

local previousMute = {}

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
		if event == watcher.screensDidSleep then
			muteDevice(audio.defaultOutputDevice())
			muteDevice(audio.defaultEffectDevice())
		elseif event == watcher.screensDidWake then
			restoreDevice(audio.defaultOutputDevice())
			restoreDevice(audio.defaultEffectDevice())
		end
	end)
	:start()
