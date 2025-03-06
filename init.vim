:" Begin vim-plug plugin section
call plug#begin('~/.local/share/nvim/plugged')

" Tokyo Night theme plugin
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-commentary'

call plug#end()

" Basic Neovim settings
syntax on
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set cursorline
set linebreak
set termguicolors
" Load your TokyoNight theme (make sure it's installed via your plugin manager)
colorscheme tokyonight-night

" Override the background for the Normal highlight group
highlight Normal guibg=none " removes backgroud color of tokyo night and makes the active editor window transparent.

nnoremap <F2> :NERDTreeToggle<CR>


autocmd VimEnter * NERDTree | wincmd p
autocmd BufEnter * if winnr("$") == 1 && exists("b:NERDTree") | quit | endif
