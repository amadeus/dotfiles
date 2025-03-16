set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

if empty(glob('~/.vim/autoload/plug.vim'))
  execute '!mkdir -p ~/.vim/bundle ~/.vim/backup ~/.vim/swap ~/.vim/cache ~/.vim/undo ~/.vim/autoload ~/.vim/bundle'
  execute '!curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin('~/.vim/bundle')

Plug 'nvim-lualine/lualine.nvim'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'easymotion/vim-easymotion'
Plug 'mhinz/vim-grepper'
Plug 'embear/vim-localvimrc'
Plug 'mhinz/vim-startify'
"Plug 'andymass/vim-matchup'
Plug 'RRethy/vim-hexokinase', {'do': 'make hexokinase'}
Plug 'simnalamburt/vim-mundo'
Plug 'junegunn/goyo.vim', {'on': 'Goyo'}
Plug 'junegunn/gv.vim', {'on': 'GV'}
Plug 'Raimondi/delimitMate'
Plug 'wellle/targets.vim'
Plug 'mattn/webapi-vim'
Plug 'mattn/vim-gist', {'on': 'Gist'}
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-obsession'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-apathy'
Plug 'roryokane/detectindent'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'cocopon/vaffle.vim'

" LSP Stuff
Plug 'nvim-lua/plenary.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'nvimtools/none-ls.nvim'

"Plug 'neovim/nvim-lspconfig' -- not sure if this is even needed, but keeping it around in case
" Not sure if i still need these, but keeping them around in case...
"Plug 'mhartington/formatter.nvim'
"Plug 'dense-analysis/ale'

" Treesitter stuff
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Testing out blink.cmp
Plug 'saghen/blink.cmp', {'tag': '*'}
" Explore this option if I want snippet support
" Plug 'rafamadriz/friendly-snippets'

" Misc Stuff -- may want to re-think this boyo
Plug 'sbdchd/neoformat'
Plug 'dhruvasagar/vim-open-url'
" This plugin is wrecking havoc on Claude Chat
" Plug 'romainl/vim-cool'
Plug 'amadeus/vim-px-to-em'
Plug 'amadeus/scratch.vim'
Plug 'amadeus/vim-convert-color-to'
Plug 'amadeus/vim-escaper'
" Plug 'amadeus/vim-evokai'
Plug 'Shatur/neovim-ayu'
Plug 'amadeus/vim-misc'
Plug 'pasky/claude.vim'

call plug#end()

" Source General VimRC
runtime! nvimrc.vim

" Source Custom VimRC
runtime! .myvimrc
