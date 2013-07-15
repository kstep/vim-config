function! HighlightLines(hlgroup, start, end)
    let signname = 'HighlightLine' . hlgroup
    let bufn = bufnr('%')

    exe 'sign define ' . signname . ' linehl=' . hlgroup
    for i in range(a:start, a:end)
        exe 'sign place 10000 line=' . i . ' name=' . signname . ' buffer=' . bufn
    endfor
endfunction

function! ToggleMinimap()
	if exists("s:isMini") && s:isMini == 0
		let s:isMini = 1
	else
		let s:isMini = 0
	end

	if (s:isMini == 0)
		" save current visible lines
		let s:firstLine = line("w0")
		let s:lastLine = line("w$")

		" resize each window
		" windo let w=winwidth(0)*12 | exe "set winwidth=" . w
		" windo let h=winheight(0)*12 | exe "set winheight=" . h

		" don't change window size
		let c = &columns * 12
		let l = &lines * 12
		exe "set columns=" . c
		exe "set lines=" . l

		" make font small
		set guifont=DejaVu\ Sans\ Mono\ 1
		
		" highlight lines which were visible
                " call HighlightLines('MinimapVisible', s:firstLine, s:lastLine)
                exe 'syn region MinimapVisible start="\%' . s:firstLine . 'l" end="\%' . s:lastLine . 'l"'
		hi MinimapVisible guibg=lightblue guifg=black term=bold
	else
		set guifont=DejaVu\ Sans\ Mono\ 11
		hi clear MinimapVisible
                syn clear MinimapVisible
                "sign undefine MinimapVisibleLine
                "redraw
	endif
endfunction

command! ToggleMinimap call ToggleMinimap()
"nnoremap m :ToggleMinimap<CR>
