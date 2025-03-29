-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- Use stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- Set up leader key before lazy setup
vim.g.mapleader = "q" -- Use space as leader key
vim.g.maplocalleader = "q"

-- Load your external configuration repository
require("lazy").setup({
  {
    -- Replace with your actual repository URL
    "amadeus/nvim-config",
    depth = false,
    -- Use the main branch (or specify another branch)
    branch = "main",
    -- Import all Neovim configuration from the repo
    import = "plugins",
    lazy = false,
    config = function()
      require('init')
    end,
    -- Optional: if your repo includes a plugin list
    dependencies = {},
    -- Optional: specify a priority to ensure it loads first
    priority = 1000,
  },
})
