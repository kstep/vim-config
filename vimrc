" .vimrc file

" Basic config & plugins loading {{{
call pathogen#infect()

syntax on
filetype plugin indent on
runtime macros/matchit.vim
" }}}

" Options {{{
silent !stty -ixon -ixoff
set helplang=ru
set t_Co=256
set t_IS=]0; t_IE=
set icon iconstring=Vim

set nohlsearch
set ignorecase
set smartcase
set incsearch

set keymap=russian-jcukenwin
set spelllang=en,ru
set imsearch=0
set iminsert=0
set grepprg=find\ %:p:h\ -xdev\ -name\ '*.%:e'\ -exec\ grep\ -Hn\ $*\ \{}\ +
set diffopt=filler,vertical

set tabstop=8
set shiftwidth=4
set softtabstop=4
set smarttab
set expandtab
set autoindent
set smartindent
set listchars=tab:»┄,eol:↲,trail:·,precedes:«,extends:»
set backspace=start,eol,indent

set foldmethod=marker
set foldlevelstart=1
set foldcolumn=1
set foldminlines=5
set numberwidth=2
set relativenumber

set window=39
set winminheight=0
set noequalalways
set ruler
set laststatus=2
set visualbell
set noerrorbells

set tildeop
set nrformats=hex,alpha
set encoding=utf-8

set linebreak
set nojoinspaces

set sessionoptions=buffers,curdir,folds,tabpages,winsize
set wildmenu

set modeline
set nobackup nowritebackup
set noswapfile
set undofile
set undodir=~/.vim/undofiles

" }}}

" Functions {{{

fun! UscorePluralToCamelSingle(value)
    let value = substitute(a:value, '_\(.\)', '\U\1', 'g')
    let value = substitute(value, '^\(.\)', '\U\1', '')
    let value = substitute(value, 'ies$', 'y', '')
    let value = substitute(value, 's$', '', '')
    return value
endfun

function! GetSelection()
	let l:line = getline("'<")
	let l:line = strpart(l:line, col("'<") - 1, col("'>") - col("'<") + 1)
	return l:line
endfunction

function! MirrorExchange(delim)
	let sel = GetSelection()
	let sel = substitute(sel, '\(.\{-}\)\('.a:delim.'\)\(.*\)', '\3\2\1', '')
	exe "norm gvc".sel."\<esc>"
endfunction
command! -range -nargs=1 MirrorExchange :call MirrorExchange(<f-args>)

function! GetSynName(...)
    let l = exists('a:1') ? a:1 : '.'
    let c = exists('a:2') ? a:2 : '.'
    return synIDattr(synID(line(l), col(c), 1), "name")
endfunction

" }}}

" Mappings & abbrevs {{{
imap ,, <Esc>

map <C-w><C-]> <C-w><C-]><C-w>T
map vA ggVG
map Y y$
map <A-w> :!pkill -USR1 fusqlfs.pl<CR>
map <Leader>p :exec 'tabedit '.getreg('*')<CR>

map <S-PageUp> gT
map <S-PageDown> gt

map <ScrollWheelLeft> gT
map <ScrollWheelRight> gt

map <S-Up> <C-W>k
map <S-Down> <C-W>j
map <S-Left> <C-W>h
map <S-Right> <C-W>l
map <C-Up> <C-W>+
map <C-Down> <C-W>-
map <C-Left> <C-W><
map <C-Right> <C-W>>

imap <S-PageUp> <Esc>gTi
imap <S-PageDown> <Esc>gti

imap <ScrollWheelLeft> <Esc>gTi
imap <ScrollWheelRight> <Esc>gti

imap <S-Insert> <C-R>=getreg('*')<CR>

vmap gx, :MirrorExchange ", "<cr>
vmap gx= :MirrorExchange " = "<cr>

vmap ,s" <Esc>`>a"<Esc>`<i"<Esc>
vmap ,s> <Esc>`>a><Esc>`<i<<Esc>
vmap ,s) <Esc>`>a)<Esc>`<i(<Esc>
vmap ,s' <Esc>`>a'<Esc>`<i'<Esc>
vmap ,s` <Esc>`>a`<Esc>`<i`<Esc>

map <C-A-a> ciw<C-R>=getreg('')*2<CR><Esc>
map <C-A-x> ciw<C-R>=getreg('')/2<CR><Esc>
map <A-a> @="yyp"<CR>

map <C-q> :quit<CR>
map <F11> :MRU<CR>
map <F10> :set list!<CR>
map <F9> :edit %:p:h<CR>

vmap ,aa :Align =><CR>
vmap ,a= :Align =<CR>

nmap ,fc :if stridx(&syntax,'.conflict')<0<Bar>setl syntax+=.conflict<Bar>endif<CR>:vimgrep "^<<<<<<<" %:p<CR>:copen<CR><CR>

imap <C-\> <C-^>
cmap <C-\> <C-^>
smap <C-\> <C-^>
nmap <C-\> a<C-^><Esc>

cabbr W w
cabbr Q q
cabbr Wq wq
cabbr WQ wq
cabbr Tabe tabe

command! WW silent! write !sudo tee %:p > /dev/null
" }}}

" Plugins config {{{
let g:gitgraph_date_format="iso"
let g:Tlist_Ctags_Cmd="/usr/bin/ctags"

"let g:dbext_default_profile_mysql_buick="type=MYSQL:user=root:passwd=nownthen:dbname=zanby5_stepanov:host=buick:extra=-vvvt"
"let g:dbext_default_profile_pgsql="type=PGSQL:user=postgres:dbname=postgres"
let g:dbext_default_DBI_max_rows=0

let g:sql_type_default="mysql"
let g:sqlutil_keyword_case='\l'
let g:sqlutil_align_comma=1

let g:Tlist_Show_One_File=1
let g:DrChipTopLvlMenu="Plugin."
let g:MRU_Max_Entries=50
let g:NERDShutUp=1

let g:vimwiki_list = [{'path': '~/.vim/wiki/', 'path_html': '~/.vim/wiki_html/', 'syntax': 'default'}]
let g:vimwiki_folding = 1
let g:vimwiki_fold_lists = 1

let g:netrw_winsize=45
let g:netrw_list_hide='^\.,\.pyc,\.pyo'
let g:netrw_cursor=2
let g:netrw_liststyle=1
let g:netrw_timefmt="%a, %e %b %Y %H:%M"
let g:netrw_keepdir=0
let g:netrw_sort_options='ni /[0-9]\+/'
let g:netrw_maxfilenamelen=64
let g:netrw_xstrlen=3
let g:netrw_list_cmd='ssh HOSTNAME ls -La'

let g:perl_include_pod=1
let g:perl_fold=1
let g:perl_nofold_subs=1

let g:po_translator = 'Konstantin Stepanov <kstep@p-nut.info>'
let g:syntastic_enable_signs=1
let g:localvimrc_ask=0
let g:localvimrc_sandbox=0
let g:gitgraph_layout = { 'g':[20,'la'], 's':[-30,'tl'], 't':[5,'rb'], 'd':[0,'br'],
            \ 'c':[10,'br'], 'v':[0,'rb'], 'f':[0,'rb'], 'r':[5,'rb'], 'l':['g','s','t'] }


let g:user_zen_settings = { 'indentation': '    ', 'mako': { 'extends': 'html' }, 'less': { 'extends': 'css' } }
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2

" }}}

" Custom highlighting {{{
set background=dark
colorscheme xoria256
"colorscheme thegoodluck
"colorscheme chocolate
" }}}

let g:tagbar_type_php = {
            \ 'ctagstype': 'PHP',
            \ 'kinds': [
            \       'c:classes',
            \       'm:methods',
            \       'f:functions'
            \ ]
        \ }

" vim: set ft=vim :

fun! GenTabLine()
    let s = ''
    for j in range(1, tabpagenr('$'))
        if j == tabpagenr()
            let s .= '%#TabLineSel#'
        else
            let s .= '%#TabLine#'
        endif

        let s .= '%' . j . 'T %{GenTabLabel(' . j . ')} '
    endfor

    let s .= '%#TabLineFill#%T'

    if tabpagenr('$') > 1
        let s .= '%=%#TabLine#%999X×%X'
    endif

    return s
endfun

fun! IsTabModified(t)
    let wins = tabpagewinnr(a:t, '$')
    for w in range(1, wins)
        if gettabwinvar(a:t, w, '&modified')
            return 1
        endif
    endfor
    return 0
endfun

fun! GenTabLabel(n)
    let buflist = tabpagebuflist(a:n)
    let winnr = tabpagewinnr(a:n)
    "let bufnr = bufnr(buflist[winnr-1])
    let bufname = bufname(buflist[winnr - 1])
    let bufname = substitute(fnamemodify(bufname, ':~:.'), '\([^/]\)[^/]\+/', '\1/', 'g')
    if IsTabModified(a:n)
        let bufname = bufname . '°'
    endif
    return a:n . ' ' . bufname
endfun

"set tabline=%!GenTabLine()

fun! MassVisualChange()
    let selection = getreg("*")
    let @/ = '\<' . selection . '\>'
    set hls
    redraw
    let replace = input("Replace with: ")
    %s//\=replace/g
    set nohls
endfun

vmap S <Esc>call MassVisualChange()<CR>

