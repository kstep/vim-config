" Vimwiki syntax file
" Trac syntax
" Author: Konstantin Stepanov <kstep@p-nut.info>
" Home: http://p-nut.info/blog/
" vim:tw=78:

let g:vimwiki_rxTable = '|.*|'
let g:vimwiki_rxBoldItalic = '\*_[^*_]\+_\*'
let g:vimwiki_rxItalicBold = '_\*[^*_]\+\*_'
let g:vimwiki_rxBold = '\*[^*]\+\*'
let g:vimwiki_rxItalic = '_[^_]\+_'
let g:vimwiki_rxSuperScript = '\^[^^]\+\^'
let g:vimwiki_rxSubScript = '\~[^~]\+\~'
let g:vimwiki_rxCode = '@[^@]\+@'
let g:vimwiki_rxHR = '^-\{4,}$'
let g:vimwiki_rxDelText = '-[^-]\+-'

let g:vimwiki_char_bold = '\*'
let g:vimwiki_char_italic = '_'
let g:vimwiki_char_bolditalic = '\*_'
let g:vimwiki_char_italicbold = '_\*'
let g:vimwiki_char_code = "@"
let g:vimwiki_char_deltext = '-'
let g:vimwiki_char_subscript = '\~'
let g:vimwiki_char_superscript = '^'

let g:vimwiki_rxH1 = '^h1\. .\+$'
let g:vimwiki_rxH2 = '^h2\. .\+$'
let g:vimwiki_rxH3 = '^h3\. .\+$'
let g:vimwiki_rxH4 = '^h4\. .\+$'
let g:vimwiki_rxH5 = '^h5\. .\+$'
let g:vimwiki_rxH6 = '^h6\. .\+$'
let g:vimwiki_rxHeader =
    \ '\(' . g:vimwiki_rxH1
    \ . '\)\|\(' . g:vimwiki_rxH2 
    \ . '\)\|\(' . g:vimwiki_rxH3 
    \ . '\)\|\(' . g:vimwiki_rxH4 
    \ . '\)\|\(' . g:vimwiki_rxH5 
    \ . '\)\|\(' . g:vimwiki_rxH6 . '\)'

let g:vimwiki_rxListBullet = '^[*]\+\s'
let g:vimwiki_rxListNumber = '^[#]\+\s'
let g:vimwiki_rxListDefine = '^.\+::\_^\s\+'

let g:vimwiki_rxPreStart = '^{{{\_^#!comment$'
let g:vimwiki_rxPreEnd = '^}}}$'

syn region wikiPreCode matchgroup=wikiCodeQuote start="^<pre>$" end="^</pre>$" contains=@wikiCodeLang fold

for wikilang in ['python', 'perl', 'php', 'c', 'crontab', 'sh', 'zsh', 'cpp', 'sql', 'ruby', 'lisp', 'scheme', 'javascript', 'vim', 'xml', 'mako']
    exec 'syn include @wikiLang' . wikilang . ' syntax/' . wikilang . '.vim'
    exec 'syn region wikiCode' . wikilang . ' matchgroup=wikiCodeQuote start="^<code class=\"' . wikilang . '\">$" end="^</code>$" contains=@wikiLang' . wikilang . ' contained'
    exec 'syn cluster wikiCodeLang add=wikiCode' . wikilang
    unlet b:current_syntax
endfor

syn match wikiUnderlinedChar /+/ contained conceal
syn match wikiUnderlined /+[^+]\++/ contains=wikiUnderlinedChar

hi link wikiUnderlinedChar Ignore

hi link wikiCodeQuote wikiComment
hi link wikiUnderlined Underlined

