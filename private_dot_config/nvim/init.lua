vim.opt.encoding = "utf-8"
vim.cmd("scriptencoding utf-8")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

-- Set up leader key before lazy setup
vim.keymap.set({ "n", "v" }, "q", "<nop>", { noremap = true })
vim.g.mapleader = "q"
vim.g.maplocalleader = "q"
vim.keymap.set({ "n", "v" }, "Q", "q", { noremap = true })

local ok, lazy = pcall(require, "lazy")
if not ok then
	vim.notify("Failed to load lazy.nvim", vim.log.levels.ERROR)
	return
end

lazy.setup({
	{
		"amadeus/nvim-config",
		branch = "main",
		import = "plugins",
		opts = {},
		config = function(_, opts)
			require("nvim-config").setup(opts)

			local local_config = vim.fn.stdpath("config") .. "/myvimrc.lua"
			if (vim.uv or vim.loop).fs_stat(local_config) then
				dofile(local_config)
			end
		end,
		priority = 1000,
	},
}, {
	dev = {
		path = "~/Developer/nvim",
		patterns = { "amadeus" },
		fallback = true,
	},
	change_detection = {
		enabled = false,
		notify = false,
	},
	ui = {
		wrap = true,
		size = { width = 0.85, height = 0.85 },
		border = "single",
		backdrop = 10,
	},
	-- Disable some built-in plugins for faster startup
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
