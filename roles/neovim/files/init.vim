" ----------------------------------------------------------------------------
"Plugin Section
" ----------------------------------------------------------------------------
call plug#begin()
" Navigation
"Plug 'nvim-lua/plenary.nvim'
"Plug 'nvim-telescope/telescope.nvim'
Plug 'preservim/nerdtree'

" IDE
"Plug 'preservim/nerdcommenter'
Plug 'neovim/nvim-lspconfig'
" Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" -- CMP
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

" -- snippet
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'onsails/lspkind.nvim'


" Color Schemes
Plug 'sonph/onehalf', { 'rtp': 'vim' }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

" ----------------------------------------------------------------------------
"  Settings Section
" ----------------------------------------------------------------------------
syntax on
filetype plugin on
filetype plugin indent on
set nocompatible
set ttyfast

set showmatch
set ignorecase 
set mouse=v 
set hlsearch
set incsearch
set tabstop=4 
set softtabstop=4
set expandtab
set shiftwidth=4
set autoindent
set number
set wildmode=longest,list
set mouse=a
set clipboard+=unnamedplus

" Color Schemes
set t_Co=256
colorscheme onehalfdark
let g:airline_theme='onehalfdark'
let mapleader="\<SPACE>"

" CMP
set completeopt=menu,menuone,noselect

lua require("cmp_conf")
lua require("lsp")
lua require("treesitter")


" ----------------------------------------------------------------------------
"  Key mapping Section
" ----------------------------------------------------------------------------
" Nerdtree
nnoremap <F2>t :NERDTreeToggle<CR>
nnoremap <F2>f :NERDTreeFind<CR>

" LSP
"nnoremap <space>e lua vim.lsp.buf.declaration()<CR>
