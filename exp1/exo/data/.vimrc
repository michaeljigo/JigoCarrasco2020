" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" Make backspace behave in a sane manner.
set backspace=indent,eol,start

" Switch syntax highlighting on
syntax enable 

" Enable file type detection and do language-dependent indenting.
filetype plugin indent on

" Show line numbers
set number

" Allow hidden buffers, don't limit to 1 file per window/split
set hidden

" Make gruvbox default colorscheme
set background=dark
colorscheme solarized

" Matlab support
source $VIMRUNTIME/macros/matchit.vim
autocmd BufEnter *.m compiler mlint

" Highlight search matches set hlsearch 
"jj exits insert mode...esc is too much of a reach
inoremap jj <ESC>

" Set tab to be only 4-spaces long
set expandtab softtabstop=3 tabstop=3 shiftwidth=3 

" Macro to align code
let @a = 'ma :%s/function/%function/ggg=G:%s/%function/function/g`a'

" Display the cursor position on the last line of the screen or in the status
" line of a window
set ruler

" Always display the status line, even if only one window is displayed
"set laststatus=2

" Instead of failing a command because of unsaved changes, instead raise a
" dialogue asking if you wish to save the changed files.
set confirm

" highlight current line
"set cursorline

" Set margin for text wrapping (wrap margin)
"set wm=5

" Open all folds when a file is opened
set foldlevelstart=30

" Don't insert new line characters when wrapping
set wrap linebreak nolist

" Do case insensitive search if lowercase letters are used
set ignorecase
set smartcase

" Save when focus is lost
set autowrite
