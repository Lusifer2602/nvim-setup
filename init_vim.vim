" navigate to end of this file to see how and where to install the config
" files

" Begin vim-plug plugin section
call plug#begin('~/.vim/plugged')

" Plugins
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'preservim/nerdtree'
" Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-commentary'
" Plug 'folke/tokyonight.nvim', { 'branch': 'main' }

call plug#end()

" Basic Vim settings
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

" Load Tokyo Night colorscheme
" colorscheme tokyonight-night

" Keybinding for toggling NERDTree
nnoremap <F2> :NERDTreeToggle<CR>

" Auto close Vim if NERDTree is the only window
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') | quit | endif

"in cases of vim (if nvim's default configuratino doesn't get applied to vim
"by default then use this configuration
"1.create a file ~/.vimrc and paste this configuration there
"
"if colors of the vim interface are not as per your convenience try toggling
"on off the :set termguicolors and Plug 'folke/tokyonight.nvim', { 'branch': 'main' } 
