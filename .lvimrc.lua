-- NOTE: Only source this file once per session
if vim.g.localvimrc_sourced_once == 1 then
	return
end

vim.g.localvimrc_sourced_once = 1
vim.g.startify_disable_at_vimenter = 1
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- ALEFix Config
vim.g.ale_fixers = {}
vim.g.ale_fix_on_save = 1

print("dotfiles repo .lvimrc has been sourced")
