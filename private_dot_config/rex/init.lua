-- Let Neovim own Ctrl+W; elsewhere use it to navigate Rex panes.
rex.action({
	name = "navigate_panes",
	title = "Navigate Panes",
	run = function(ctx)
		local process
		if ctx.block_id then
			process = rex.block.call("com.superlogical.terminal", "process", {
				block_id = ctx.block_id,
			})
		end

		local passthrough = false
		if process then
			passthrough = process.foreground ~= nil and process.foreground.name == "nvim"
			for _, ancestor in ipairs(process.ancestors or {}) do
				passthrough = passthrough or ancestor.name == "nvim"
			end
		end

		if passthrough then
			rex.client.queue("pane.send_key", { key = "ctrl+w" })
		else
			rex.client.queue("client.mode.enter", { name = "panes", once = true })
		end
	end,
})
rex.bind("ctrl+w", "navigate_panes")

rex.mode("panes", { exclusive = true })
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("panes/" .. key, "pane.focus", { direction = direction, wrap = false })
	rex.bind("panes/ctrl+" .. key, "pane.focus", { direction = direction, wrap = false })
end

rex.bind("panes/v", "pane.split", { direction = "right" })
rex.bind("panes/s", "pane.split", { direction = "down" })
rex.bind("panes/t", "client.tab.next")
rex.bind("panes/shift+t", "client.tab.previous")

-- Escape cancels the mode; Ctrl+W twice sends Ctrl+W to the terminal.
rex.bind("panes/ctrl+w", "pane.send_key", { key = "ctrl+w" })
