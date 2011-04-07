" .vimrc file

" Basic config & plugins loading {{{
call pathogen#runtime_append_all_bundles()

syntax on
filetype plugin on
filetype indent on
runtime macros/matchit.vim
" }}}

" Options {{{
set helplang=ru
set t_IS=]0; t_IE=
set icon iconstring=Vim

set nohlsearch
set ignorecase
set smartcase
set incsearch

set keymap=russian-jcukenwin
"set langmap=йцукенгшщзхъфывапролджэячсмитьбюЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ;qwertyuiop\[\]asdfghjkl\\;\'zxcvbnm\\,\.QWERTYUIOP\{\}ASDFGHJKL\:\"ZXCVBNM\<\>
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
set listchars=tab:»\ ,eol:¶,trail:·,precedes:«,extends:»
set backspace=start,eol,indent

set foldmethod=marker
set foldlevelstart=1
set foldcolumn=1

set window=39
set winminheight=0
set noequalalways
set ruler

set tildeop
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
fun! BugzSearch(params)
	let cmd = '~/bin/bug search '
	let cmd = cmd . a:params
	tabedit
	file "bugz"
	setl bt=nofile enc=latin1
	exec 'read !'.cmd
        setl enc=utf-8
endfun


fun! UscorePluralToCamelSingle(value)
    let value = substitute(a:value, '_\(.\)', '\U\1', 'g')
    let value = substitute(value, '^\(.\)', '\U\1', '')
    let value = substitute(value, 'ies$', 'y', '')
    let value = substitute(value, 's$', '', '')
    return value
endfun

fun! TableToModel()
    '<,'>s/^.*=\s*Table(\('\)\([a-z0-9_]\+\)\1.*$/\='class '.UscorePluralToCamelSingle(submatch(2)).'(ActiveModel):'."\n    __tablename__ = '".submatch(2)."'\n"/e
    '<,'>s/Column('\([a-z_]\+\)', /\1 = Column(/e
    '<,'>s/,$//e
    '<,'>s/ \{8}/    /e
    '<,'>s/^\s*)\s*$//e
endfun

" a:1 - lang
fun! ScanText(...)
    let lang = exists('a:1') ? a:1 : 'ruseng'
    setl enc=latin1
    exec 'read !cuneiform -f smarttext -l '.lang.' -o /dev/stdout <(scanimage --format=tiff --resolution=300dpi --mode=Gray)'
    setl enc=utf8
endfun

fun! MigrateScript()
    if !exists('g:project_dir') || empty(g:project_dir)
        echoerr "Set g:project_dir to project directory in order to create new migration script!"
        return
    endif
    let migrate_repo = g:project_dir.'/migrations'
    let migrate_wrapper = migrate_repo.'/manage.py'
    let migrate_script=input('Migration script name: ')

    if empty(migrate_script) | return | endif

    call system(migrate_wrapper . ' script ' . shellescape(migrate_script))
    let migrate_version = system(migrate_wrapper . ' version')
    if empty(migrate_version) | return | endif

    let migrate_file = glob(printf(migrate_repo.'/versions/%03d_*.py', migrate_version))
    exec 'tabedit '.migrate_file
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

function! SignMark(type)
    let bufno = bufnr('%')
    let lineno = line('.')
    exe 'sign define mark'.a:type.' text='.a:type.'> texthl=Question linehl=SignLine'
    exe 'sign place '.(lineno*100000+bufno*100+a:type).' line='.lineno.' name=mark'.a:type.' buffer='.bufno
endfunction

function! UnSignMark(type)
    let bufno = bufnr('%')
    let lineno = line('.')
    exe 'sign unplace '.(lineno*100000+bufno*100+a:type).' buffer='.bufno
endfunction

function! GetSynName(l, c)
    echo synIDattr(synID(line(a:l), col(a:c), 1), "name")
endfunction

" Interface functions
function! SetFiletype(ft)
    let &filetype=a:ft
endfunction

function! HighlightLine(s,l)
    exec 'syn match '.a:s.' /\%'.a:l.'l.*$/'
endfunction

" }}}

" Mappings & abbrevs {{{
map <C-w><C-]> <C-w><C-]><C-w>T
map vA ggVG
imap <A-q> <C-^>
map <A-w> :!pkill -USR1 fusqlfs.pl<CR>
"noremap by "+y
"noremap bp "+p

map <A-1> 1gt
map <A-2> 2gt
map <A-3> 3gt
map <A-4> 4gt
map <A-5> 5gt
map <A-6> 6gt
map <A-7> 7gt
map <A-8> 8gt
map <A-9> 9gt
map <A--> :tabedit<CR>
map <S-PageUp> gT
map <S-PageDown> gt
map <S-Up> <C-W>k
map <S-Down> <C-W>j
map <S-Left> <C-W>h
map <S-Right> <C-W>l
map <C-Up> <C-W>+
map <C-Down> <C-W>-
map <C-Left> <C-W><
map <C-Right> <C-W>>

imap <A-1> <Esc>1gti
imap <A-2> <Esc>2gti
imap <A-3> <Esc>3gti
imap <A-4> <Esc>4gti
imap <A-5> <Esc>5gti
imap <A-6> <Esc>6gti
imap <A-7> <Esc>7gti
imap <A-8> <Esc>8gti
imap <A-9> <Esc>9gti
imap <A--> <Esc>:tabedit<CR>i
imap <S-PageUp> <Esc>gTi
imap <S-PageDown> <Esc>gti

vnoremap gw <Esc>`>a')}<Esc>`<i${_(u'<Esc>
vmap gx, :call MirrorExchange(", ")<cr>
vmap gx= :call MirrorExchange(" = ")<cr>
map <Leader>mm :call MigrateScript()<CR>

vmap ,s" <Esc>`>a"<Esc>`<i"<Esc>
vmap ,s> <Esc>`>a><Esc>`<i<<Esc>
vmap ,s) <Esc>`>a)<Esc>`<i(<Esc>
vmap ,s' <Esc>`>a'<Esc>`<i'<Esc>
vmap ,s` <Esc>`>a`<Esc>`<i`<Esc>

map <C-A-A> ciw<C-R>=getreg('')*2<CR><Esc>
map <C-A-X> ciw<C-R>=getreg('')/2<CR><Esc>

map <C-q> :quit<CR>
map <Leader>\ :TlistToggle<CR>
map <Leader>' :30Vexplore<CR>
map <F11> :MRU<CR>
map <F10> :set list!<CR>
map <F9> :edit %:p:h<CR>
map <Leader>= :<C-U>call SignMark(v:count1)<CR>
map <Leader>- :<C-U>call UnSignMark(v:count1)<CR>
map <Leader>_ :sign unplace *<CR>
map <Leader>cb :VCSAnnotate<CR>

vmap ,aa :Align =><CR>
vmap ,a= :Align =<CR>

nmap ,fc :if stridx(&syntax,'.conflict')<0<Bar>setl syntax+=.conflict<Bar>endif<CR>:vimgrep "^<<<<<<<" %:p<CR>:copen<CR><CR>

imap <Delete> <C-^>
cmap <Delete> <C-^>
smap <Delete> <C-^>
nmap <Delete> a<C-^>

cabbr W w
cabbr Q q
cabbr Wq wq
cabbr WQ wq
cabbr Tabe tabe

command! WW write !sudo tee %:p > /dev/null
" }}}

" Signs {{{
sign define stop text=!! texthl=Error linehl=SignLine
" }}}

" Plugins config {{{
let g:gitgraph_date_format="iso"

let g:Tlist_Ctags_Cmd="/usr/bin/ctags"
let g:VCSCommandSVNExec="/usr/bin/svn"

"let g:dbext_default_profile_mysql_buick="type=MYSQL:user=root:passwd=nownthen:dbname=zanby5_stepanov:host=buick:extra=-vvvt"
let g:dbext_default_profile_pgsql="type=PGSQL:user=postgres:dbname=postgres"
let g:dbext_default_profile_pgsql_unite="type=PGSQL:user=postgres:dbname=unite_dev"
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

let g:vimwiki_list = [{'path': '~/.vim/wiki/', 'path_html': '~/.vim/wiki_html/', 'syntax': 'trac'}]

let g:netrw_winsize=45
let g:netrw_list_hide='^\.,\.pyc'
let g:netrw_cursorline=1
let g:netrw_liststyle=1
let g:netrw_timefmt="%a, %e %b %Y %H:%M"
let g:netrw_keepdir=0
let g:netrw_sort_options='ni /[0-9]\+/'
let g:netrw_maxfilenamelen=64
let g:netrw_xstrlen=3

let g:perl_include_pod=1
let g:perl_fold=1
let g:perl_nofold_subs=1

let g:syntastic_enable_signs=1
let g:localvimrc_ask=0
let g:localvimrc_sandbox=0
let g:gitgraph_layout = { 'g':[20,'la'], 's':[-30,'tl'], 't':[5,'rb'], 'd':[0,'br'],
            \ 'c':[10,'br'], 'v':[0,'rb'], 'f':[0,'rb'], 'r':[5,'rb'], 'l':['g','s','t'] }


let g:user_zen_settings = { 'mako': { 'extends': 'html' } }


" }}}

" Custom highlighting {{{
set background=dark
colorscheme peaksea
" }}}

" vim: set ft=vim :

