" Vimwiki syntax file
" Trac syntax
" Author: Konstantin Stepanov <kstep@p-nut.info>
" Home: http://p-nut.info/blog/
" vim:tw=78:

let g:vimwiki_rxTable = '||.*||'
let g:vimwiki_rxBoldItalic = "'''''[^']\\+'''''"
let g:vimwiki_rxItalicBold = g:vimwiki_rxBoldItalic
let g:vimwiki_rxBold = "'''[^']\\+'''"
let g:vimwiki_rxItalic = "''[^']\\+''"
let g:vimwiki_rxSuperScript = '\^[^^]\+\^'
let g:vimwiki_rxSubScript = ',,[^,]\+,,'
let g:vimwiki_rxCode = '`[^`]\+`'
let g:vimwiki_rxHR = '^-\{4,}$'
let g:vimwiki_rxDelText = '\~\~[^~]\+\~\~'

let g:vimwiki_rxH1 = '^=\{1} [^=]\+ =\{1}$'
let g:vimwiki_rxH2 = '^=\{2} [^=]\+ =\{2}$'
let g:vimwiki_rxH3 = '^=\{3} [^=]\+ =\{3}$'
let g:vimwiki_rxH4 = '^=\{4} [^=]\+ =\{4}$'
let g:vimwiki_rxH5 = '^=\{5} [^=]\+ =\{5}$'
let g:vimwiki_rxH6 = '^=\{6} [^=]\+ =\{6}$'
let g:vimwiki_rxHeader =
    \ '\(' . g:vimwiki_rxH1
    \ . '\)\|\(' . g:vimwiki_rxH2 
    \ . '\)\|\(' . g:vimwiki_rxH3 
    \ . '\)\|\(' . g:vimwiki_rxH4 
    \ . '\)\|\(' . g:vimwiki_rxH5 
    \ . '\)\|\(' . g:vimwiki_rxH6 . '\)'

let g:vimwiki_rxListBullet = '^\s\+[*]'
let g:vimwiki_rxListNumber = '^\s\+\([0-9]\{1,5}\|[a-z]\{1,5}\)\.'
let g:vimwiki_rxListDefine = '^.\+::\_^\s\+'

let g:vimwiki_rxPreStart = '^{{{\_^#!comment$'
let g:vimwiki_rxPreEnd = '^}}}$'

syn region wikiPreCode matchgroup=wikiCodeQuote start="^{{{$" end="^}}}$" contains=@wikiCodeLang fold

for wikilang in ['python', 'perl', 'php', 'c', 'crontab', 'sh', 'zsh', 'cpp', 'sql', 'ruby', 'lisp', 'scheme', 'javascript', 'vim']
    exec 'syn include @wikiLang' . wikilang . ' syntax/' . wikilang . '.vim'
    exec 'syn region wikiCode' . wikilang . ' matchgroup=wikiCodeQuote start="^#!' . wikilang . '$" end="\(^}}}$\)\@=" contains=@wikiLang' . wikilang . ' contained'
    exec 'syn cluster wikiCodeLang add=wikiCode' . wikilang
    unlet b:current_syntax
endfor

hi link wikiCodeQuote wikiComment

"" URL link
"syn region wikiLink start="\[" end="\]"
"" changeset links
"syn match wikiLink "\<r[a-f0-9]\+\>"
"syn match wikiLink "\[[a-f0-9]\+\]"
"" ticket link
"syn match wikiLink "\<#\d\+\>"
"" report link 
"syn match wikiLink "\<{\d\+}\>"
"" alternative syntax
"syn match wikiLink "\<\(changeset\|ticket\|report\):[a-f0-9]\+\>"
"" TODO: a lot of other links are possible

"syn region wikiImage start="\[\[Image(" end=")\]\]"
"syn region wikiMacros start="\[\[[A-Za-z0-9]\+(" end=")\]\]"

