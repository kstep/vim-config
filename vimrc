" .vimrc file

" Basic config & plugins loading {{{
syntax on
filetype plugin on
filetype indent on
runtime macros/matchit.vim
" }}}

" Options {{{
set guifont=DejaVu\ Sans\ Mono\ 10
set helplang=ru
set t_IS=]0; t_IE=
set icon iconstring=Vim

set nohlsearch
set ignorecase
set smartcase

set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0
set incsearch
set grepprg=find\ %:p:h\ -xdev\ -name\ '*.%:e'\ -exec\ grep\ -Hn\ $*\ \{}\ +

set tabstop=8
set shiftwidth=4
set softtabstop=4
set smarttab
set expandtab
set autoindent
set smartindent

set foldmethod=marker
set foldlevelstart=1

set window=39
set winminheight=0
set noequalalways

set tildeop
set encoding=utf-8

set linebreak
set nojoinspaces

set sessionoptions+=globals,localoptions,resize,winpos
set wildmenu

set modeline

" }}}

" Functions {{{
function! GetSelection()
	let l:line = getline("'<")
	let l:line = strpart(l:line, col("'<") - 1, col("'>") - col("'<") + 1)
	return l:line
endfunction

function! MirrorExchange(delim)
	let l:sel = GetSelection()
	let l:sel = substitute(l:sel, '\(.*\)\('.a:delim.'\)\(.*\)', '\3\2\1', '')
	exe "norm gvc".l:sel."\<esc>"
endfunction

function! SignMark(type)
	exe "sign place " . line(".") . " line=" . line(".") . " name=" . a:type . " file=" . expand("%:p")
endfunction

function! UnSignMark()
	exe "sign unplace " . line(".") . " file=" . expand("%:p")
endfunction

function! GetSynName(l, c)
    echo synIDattr(synID(line(a:l), col(a:c), 1), "name")
endfunction
" }}}

" Mappings & abbrevs {{{
map <C-w><C-]> <C-w><C-]><C-w>T
noremap vA ggVG
noremap by "+y
noremap bp "+p

noremap <A-1> 1gt
noremap <A-2> 2gt
noremap <A-3> 3gt
noremap <A-4> 4gt
noremap <A-5> 5gt
noremap <A-6> 6gt
noremap <A-7> 7gt
noremap <A-8> 8gt
noremap <A-9> 9gt
noremap <S-Left> gT
noremap <S-Right> gt

inoremap <A-1> <Esc>1gti
inoremap <A-2> <Esc>2gti
inoremap <A-3> <Esc>3gti
inoremap <A-4> <Esc>4gti
inoremap <A-5> <Esc>5gti
inoremap <A-6> <Esc>6gti
inoremap <A-7> <Esc>7gti
inoremap <A-8> <Esc>8gti
inoremap <A-9> <Esc>9gti
inoremap <S-Left> <Esc>gTi
inoremap <S-Right> <Esc>gti

noremap ,x, :call MirrorExchange(", ")<cr>
noremap ,x= :call MirrorExchange(" = ")<cr>

vnoremap s" <Esc>`>a"<Esc>`<i"<Esc>
vnoremap s> <Esc>`>a><Esc>`<i<<Esc>
vnoremap s) <Esc>`>a)<Esc>`<i(<Esc>
vnoremap s' <Esc>`>a'<Esc>`<i'<Esc>

noremap <Leader>\ :TlistToggle<CR>
noremap <Leader>' :30Vexplore<CR>
noremap <F11> :tabe ~/.vim_mru_files<CR>
noremap <F10> :set list!<CR>
noremap <Leader>= :call SignMark("mark")<CR>
noremap <Leader>- :call UnSignMark()<CR>
noremap <Leader>_ :sign unplace *<CR>
noremap <Leader>cb :VCSAnnotate<CR>

vnoremap ,aa :Align =><CR>
vnoremap ,a= :Align =<CR>

cabbr W w
cabbr Q q
cabbr Wq wq
cabbr WQ wq
cabbr Tabe tabe

command WW write !sudo tee %:p > /dev/null
" }}}

" Signs {{{
sign define mark text=>> texthl=Question linehl=SignLine
sign define stop text=!! texthl=Error linehl=SignLine
" }}}

" Plugins config {{{
let g:gitgraph_date_format="relative"

let g:Tlist_Ctags_Cmd="/usr/bin/ctags"
let g:VCSCommandSVNExec="/usr/bin/svn"

"let g:dbext_default_profile_mysql_buick="type=MYSQL:user=root:passwd=nownthen:dbname=zanby5_stepanov:host=buick:extra=-vvvt"
let g:dbext_default_profile_pgsql="type=PGSQL:user=postgres:dbname=postgres"
let g:dbext_default_profile_pgsql_spisoc="type=PGSQL:user=postgres:dbname=spisoc"
let g:dbext_default_profile_mysql_icart_dev="type=MYSQL:user=root:dbname=icart_dev:passwd=vecrekhen"
let g:dbext_default_DBI_max_rows=0

let g:sql_type_default="mysql"
let g:sqlutil_keyword_case='\l'
let g:sqlutil_align_comma=1

let g:MRU_Max_Entries=50
let g:Tlist_Show_One_File=1
let g:DrChipTopLvlMenu="Plugin."

let g:NERDShutUp=1
let g:NERDTreeHijackNetrw=0
let g:NERDTreeChDirMode=2

let g:CodeCompl_Complete_File="templates/default_snippets.template"
let g:CodeCompl_Hotkey=";;"

let g:vimwiki_list = [{'path': '~/.vim/wiki/', 'path_html': '~/.vim/wiki_html/', 'syntax': 'trac'}]

let g:netrw_liststyle=1
let g:netrw_list_hide="^\\."
let g:netrw_timefmt="%a, %e %b %Y %H:%M"
let g:netrw_keepdir=0

let g:localvimrc_ask=0

" }}}

" Custom highlighting {{{
colorscheme elflord
set background=light
if &term == "screen"
    "let &t_SI = "[4h"
    "let &t_EI = "[4l"
elseif &term == "rxvt-256color"
    let &t_SI = "]12;orange"
    let &t_EI = "]12;green"
endif
" }}}

" vim: set ft=vim :

