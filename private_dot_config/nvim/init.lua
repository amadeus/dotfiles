vim.opt.encoding = "utf-8"
vim.cmd("scriptencoding utf-8")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
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
vim.keymap.set("n", "q", "<nop>", { noremap = true })
vim.keymap.set("v", "q", "<nop>", { noremap = true })
vim.g.mapleader = "q"
vim.g.maplocalleader = "q"
vim.keymap.set("n", "Q", "q", { noremap = true })
vim.keymap.set("v", "Q", "q", { noremap = true })

-- Load your external configuration repository
require("lazy").setup({
	{
		"amadeus/nvim-config",
		depth = true,
		branch = "main",
		import = "plugins",
		lazy = false,
		config = function()
			require("init")
			pcall(function()
				dofile(vim.fn.stdpath("config") .. "/myvimrc.lua")
			end)
		end,
		priority = 1000,
	},
}, {
	change_detection = {
		enabled = false,
		notify = false,
	},
	ui = {
		wrap = true,
		size = { width = 0.85, height = 0.85 },
		border = "none",
		backdrop = 20,
	},
})
