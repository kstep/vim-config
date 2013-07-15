"
"                                ToggleOnly.vim:                           
"
"   			A reworking of the ^W^O "Only window" idea of maximizing
"   			the current window, but also maximize the new one as you
"   			switch windows.
"
" Version:		1.1
"
" Author:		Eric Arnold ( eric_p_arnold in_the_vicinity_of yahoo.com )
"
" Description:	Remaps ^W^O   ^W^W   ^W^K   and a few related keys to
" 				fully expand the current window without closing any.
" 				Emphasis is on simplicity, key ergonomics and usability.
" 				I wanted something I would actually use all the time.
" 				Your [personal preference] milage may vary.  I used the
" 				^W keys to move through windows before, so tried to
" 				integrate smoothly with them.  Small bumps in the
" 				original are smoothed out, i.e. ^W^J and ^W^K wrap
" 				around.
"
" <C-W><C-O>	Toggle the Only Window Mode ON/OFF.   
" 				<C-W><C-O>   <C-W><C-_>   <C-W>o   are synonymous.
" 				<C-W>O toggles auto-expand.
" 				The rest of the keys are only mapped when Only Window Mode ON.
"
" Mouse			Window will resize when the mouse cursor enters it or
"				its [clicked]statusbar.  See config section.
"
"
" <C-W><C-K>	Up one window, resize to full, wrap around at top.
"
" <C-W><C-W>	Next/Down one window, ditto.  
" 				<C-W><C-J> is synonymous.
"
" <C-W>w or j	Next window, and resize to 1/2 total &lines, giving the
"				previous window the other half, wrap around at bottom.
"				These provide a way to move around with a little more
"				visibility without leaving Only Window Mode.
"
" <C-W>k		Previous window, ditto.
"
"
"		Note:  if  "g:ToggleOnlyAutoExpand"  is set (true by default),
"		windows will be expanded when *anything* moves the cursor into
"		them.
"
"
"
"	Configuration Notes:	
"
"		Whether you need to click on the statusbar depends on how you
"		have "&mousefocus" set.  You can tone down the aggressive
"		behavior of the auto-expand by turning "&mousefocus" off,
"		without disabliing auto-expand altogether.
"
"
"		"timeout" and "ttimeout" are turned off since it's extra
"		annoying when it times out to the default ^W^O, which closes all
"		other windows.  You may want to reset these if you have
"		mappings like   ,s  and   ,st    which depend on a timeout 
"		for  ,s   to be accepted, or some other key, i.e.  ,s<ESC>   
"		works without timeouts.
"		"g:ToggleOnlyTimeouts"  is "exe"'d, so get your syntax
"		right.  If want timeouts, try something like this in your
"		".vimrc":
"
"	let g:ToggleOnlyTimeouts = 'set timeout ttimeout timeoutlen=2000 ttimeoutlen=2000'
"
"		An autocommand is set for "BufEnter" to resize any window, 
"		which allows you to mouse into a window and have it resize.
"		This is controled by:
"
"	let g:ToggleOnlyAutoExpand = 1
"
"		To save space when the windows are minimized, "&winminheight" is
"		set to zero.  This is changed with:
"
"	let g:ToggleOnlywinminheight = 0
"
"
"
"	Updated:		Wed Jun 08, 6/8/2005 5:14:07 PM
" 		General overall refinement.
" 	-	Now uses ^K and k, ^W and w, which is better than O and o.
" 	-	All keys wrap around at top/bottom, not just ^W.
" 	-	Added a BufEnter autocommand so mouse will trigger resize
" 	-	Keymaps are more correct (nnoremap instead of map), and are
" 		only mapped when ^W^O toggles them on.
"	-	Set &winminheight to 0 to save space around statusbars.
"	-	Added a few config options.  Keymap timeout issue addressed, and
"		config option added.
"	-	Added a two window auto expand option



if !exists('g:ToggleOnlyAutoExpand')
	let g:ToggleOnlyAutoExpand = 1
endif
"let g:ToggleOnlyTimeouts = 'set timeout ttimeout timeoutlen=3000 ttimeoutlen=3000'
if !exists('g:ToggleOnlyTimeouts ')
	let g:ToggleOnlyTimeouts = 'set notimeout nottimeout'
endif
if !exists('g:ToggleOnlywinminheight ')
	let g:ToggleOnlywinminheight = 0
endif


let s:Resize_command = 'resize'
let s:Resize_ok = 1

function! ToggleOnly( inp )

	if ( !exists( "g:ToggleOnlyToggle" ) )
		let g:ToggleOnlyToggle = 0
	endif

	if a:inp ==# 'O'
		if g:ToggleOnlyAutoExpand
			echo "Auto Expand is now OFF"
			let g:ToggleOnlyAutoExpand = 0
		else
			echo "Auto Expand is now ON"
			let g:ToggleOnlyAutoExpand = 1
		endif
		return
	endif

	if ( g:ToggleOnlyToggle == 0 )
		let g:ToggleRestore = winrestcmd()
		let g:ToggleOnlyToggle = 1
		echo "Only Window Mode is ON.  Saving all window sizes"
		resize

		nnoremap <silent> <C-W>w		:call ToggleOnlyMove( 'C-Ww')<CR>
		nnoremap <silent> <C-W>j		:call ToggleOnlyMove( 'C-Wj')<CR>
		nnoremap <silent> <C-W>k		:call ToggleOnlyMove( 'C-Wk')<CR>
		nnoremap <silent> <C-W><C-K>	:call ToggleOnlyMove( 'C-WC-K')<CR>
		nnoremap <silent> <C-W><C-W>	:call ToggleOnlyMove( 'C-WC-W')<CR>
		nnoremap <silent> <C-W><C-J>	:call ToggleOnlyMove( 'C-WC-J')<CR>


		aug ToggleOnlyAutocommands
			au BufEnter	* call ToggleOnlyBufEnter() 
		aug end

		exe g:ToggleOnlyTimeouts

		let &winminheight = g:ToggleOnlywinminheight

	else

		exe g:ToggleRestore
		let g:ToggleOnlyToggle = 0
		echo "Only Window Mode is OFF.  Restoring all window sizes"

		silent! unmap <C-W>w
		silent! unmap <C-W>j
		silent! unmap <C-W>k
		silent! unmap <C-W><C-K>
		silent! unmap <C-W><C-W>
		silent! unmap <C-W><C-J>

		aug ToggleOnlyAutocommands
			au!
		aug end

	endif

endfunction



function! ToggleOnlyMove( inp )

	if !g:ToggleOnlyToggle
		return
	endif

	if a:inp ==# "C-WC-K"
		let s:Resize_command = 'resize'
		if winnr() ==# 1
			silent exe 'normal! ' . "\<C-W>\<C-B>"
		else
			silent exe 'normal! ' . "\<C-W>\<C-K>"
		endif
		silent resize
	elseif a:inp ==# "C-WC-W" || a:inp ==# "C-WC-J"
		let s:Resize_command = 'resize'
		" Last window wrapping is all done by sending ^W^W instead of
		" the original key.
		silent exe 'normal! ' . "\<C-W>\<C-W>"
		silent resize
	elseif a:inp ==# "C-Ww" || a:inp ==# "C-Wj"
		let s:Resize_command = 'resize ' . (&lines / 2)
		let s:Resize_ok = 0
		silent resize	" First, prepare by squeezing everything else.
		silent exe 'normal! ' . "\<C-W>\<C-W>"
		silent exe s:Resize_command
	elseif a:inp ==# "C-Wk"
		let s:Resize_command = 'resize ' . (&lines / 2)
		let s:Resize_ok = 0
		silent resize
		if winnr() ==# 1
			silent exe 'normal! ' . "\<C-W>\<C-B>"
		else
			silent exe 'normal! ' . "\<C-W>\<C-K>"
		endif
		silent exe s:Resize_command
	endif

endfunction



function! ToggleOnlyBufEnter() 
	if !g:ToggleOnlyAutoExpand
		return
	endif

	silent exe s:Resize_command

	if s:Resize_ok
	else
		let s:Resize_ok = 1
	endif
endfunction

silent! unmap <C-W><C-_>
silent! unmap <C-W><C-O>
silent! unmap <C-W>o
silent! unmap <C-W>O
nnoremap <C-W><C-O>  :call ToggleOnly( 'C-WC-O' )<CR>
nnoremap <C-W><C-_>  :call ToggleOnly( 'C-WC-_' )<CR>
nnoremap <C-W>o  :call ToggleOnly( 'o' )<CR>
nnoremap <C-W>O  :call ToggleOnly( 'O' )<CR>


" vim6:fdm=marker:foldenable:ts=4:sw=4
