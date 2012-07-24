" local syntax file - set colors on a per-machine basis:
" vim: tw=0 ts=4 sw=4
" Vim color file
" Last Change:	2008 June 03
" Based on granate.vim by Ron Aaron and 'chocolate' from W3C core styles

hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "chocolate"
hi Normal		  guifg=#D0FFD0 guibg=#212121
hi Scrollbar	  guifg=darkcyan guibg=cyan
hi Menu			  guifg=black guibg=cyan
hi SpecialKey	  term=bold  cterm=bold  ctermfg=darkred  guifg=brown
hi NonText		  term=bold  cterm=bold  ctermfg=darkred  gui=bold	guifg=white
hi Directory	  term=bold  cterm=bold  ctermfg=brown	guifg=brown
hi ErrorMsg		  term=standout  cterm=bold  ctermfg=grey  ctermbg=blue  guifg=White  guibg=Red
hi Search		  term=reverse	ctermfg=white  ctermbg=red	guifg=white  guibg=#7080dd gui=bold
hi MoreMsg		  term=bold  cterm=bold  ctermfg=darkgreen	gui=bold  guifg=SeaGreen
hi ModeMsg		  term=bold  cterm=bold  gui=bold  guifg=White	guibg=Blue
hi LineNr		  term=underline  cterm=bold  ctermfg=darkcyan	guifg=#707070
hi Question		  term=standout  cterm=bold  ctermfg=darkgreen	gui=bold  guifg=Green
hi StatusLine	  term=bold,reverse  cterm=bold ctermfg=lightblue ctermbg=white gui=bold guifg=blue guibg=white
hi StatusLineNC   term=reverse	ctermfg=white ctermbg=lightblue guifg=white guibg=blue
hi Title		  term=bold  cterm=bold  ctermfg=darkmagenta  gui=bold	guifg=#a05000
hi Visual		  term=reverse	cterm=reverse  gui=reverse
hi WarningMsg	  term=standout  cterm=bold  ctermfg=darkblue  guifg=Red
hi Cursor		  guifg=bg	guibg=Green
hi CursorLine	  guifg=bg	guibg=grey30
hi Comment		  term=bold  cterm=bold ctermfg=cyan  guifg=#30ff25
hi Constant		  term=underline  cterm=bold ctermfg=magenta  guifg=#FFCC00
hi Special		  term=bold  cterm=bold ctermfg=red  guifg=yellow gui=bold
hi Identifier	  term=underline   ctermfg=brown  guifg=white
hi Function		  guifg=#990000 gui=bold
hi Operator		  guifg=white
hi Statement	  term=bold  cterm=bold ctermfg=yellow	guifg=#ffffff gui=bold
hi PreProc		  term=underline  ctermfg=darkblue	guifg=yellow gui=bold
hi Type			  term=underline  cterm=bold ctermfg=lightgreen  gui=bold  guifg=#dddddd
hi Error		  term=reverse	ctermfg=darkcyan  ctermbg=white guifg=Red	guibg=white
hi Todo			  term=standout  ctermfg=black	ctermbg=darkcyan  guifg=#f5f5f5 guibg=#aa4040 gui=bold
hi VertSplit	  guibg=#505050 guifg=white
hi link IncSearch		Visual
hi link String			Constant
hi link Character		Constant
hi link Number			Constant
hi link Boolean			Statement
hi link Float			Number
" hi link Function		Identifier
hi link Conditional		Statement
hi link Repeat			Statement
hi link Label			Statement
" hi link Operator		Statement
hi link Keyword			Statement
hi link Exception		Statement
hi link Include			PreProc
hi link Define			PreProc
hi link Macro			PreProc
hi link PreCondit		PreProc
hi link StorageClass	Type
hi link Structure		Type
hi link Typedef			Type
hi link Tag				Special
hi link SpecialChar		Special
hi link Delimiter		Special
hi link SpecialComment	Special
hi link Debug			Special


