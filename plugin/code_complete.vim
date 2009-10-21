" ========================================================================
" File:             code_complete.vim
" Features:         function parameter complete, code snippets, and
"                   much more.
" Original Author:  Mingbai <mbbill AT gmail DOT com> 
" Maintainer:       StarWing <weasley_wx AT qq DOT com>
" Last Change:      2008-11-11 17:14:03
" Version:          2.8.1
" Details: {{{1
" Install:          1.  Put code_complete.vim and my_snippets.template
"                       to plugin directory.
"                   2.  Use the command below to create tags file
"                       including signature field.
"                       ctags -R --c-kinds=+p --fields=+S .
"
" Usage:
"                   Hotkey:
"
"                       "<A-d>" (default value of g:CodeCompl_Hotkey)
"                       we DON'T use <tab>, because it comflict with
"                       superstab.vim, you will quickly find Alt-S
"                       will be a good choice.  Do all the jobs with
"                       this key, see example:
"                       press <A-d> after function name and (
"                           foo ( <A-d>
"                       becomes:
"                           foo ( `<first param>`,`<second param>` )
"                       press <A-D> after code template
"                           if <A-d>
"                       becomes:
"                           if( `<...>` )
"                           {
"                               `<...>`
"                           }
"
"                   Commands:
"                       
"                       StartCodeComplele
"                           make code_complete work, it will be called
"                           when you edit a new buffer
"
"                       StopCodeComplete
"                           Just stop code_complete, and free all
"                           memory use.
"
"                       UpdateTemplate
"                           Update your filelist and template folder
"                           and your complete file(named as
"                           my_snippets.template defaultly), will
"                           called by code_complete when you edit new
"                           buffer, or change your filetype if you set
"                           g:CodeCompl_SaveListInBuffer
"
"                       EditSnippets
"                           Edit your complete file.
"
"                       SaveAsTemplate
"                           Save current file to template folder, and
"                           use your filetype for postfix name, maybe
"                           you should add a bang if there are
"                           same-name file in your template folder
"                           
"                   variables:
"
"                       g:CodeCompl_Hotkey
"                           the key used to complete function
"                           parameters and key words. after you press
"                           ths key AFTER you input the complete-word,
"                           the word will be spreaded. you can see the
"                           paragraph above for detail features.
"
"                       g:CodeCompl_RegionStart g:CodeCompl_RegionEnd
"                           region start and stop you can change them
"                           as you like.  but you must be careful,
"                           because we use them to detemin marks in
"                           your template files(not complete file), so
"                           if you change it, maybe you must
"                           substitute all marks in your template
"                           files. after you change them, maybe you
"                           should update your template file, you can
"                           use this command:
"                           :UpdateTemplate<CR>
"
"                       g:CodeCompl_Template_RegionStart
"                       g:CodeCompl_Template_RegionEnd
"                           region start and stop the template file.
"                           you can change them to match the marks in
"                           your template file.
"
"                       g:CodeCompl_Template_Forechar
"                           you can use template file with
"                           template-forechar, you can create a file
"                           named 'complete-word.filetype',
"                           and drop it in
"                           g:CodeCompl_Template_Folder(default, it's
"                           'templates' in your runtimepath, e.g.
"                           D:\Vim\vimfiles\templates in windows, or
"                           /root/.vim/templates in linux/unix.
"                           after you create file, you can input
"                           forechar + complete-word to include the
"                           whole file. e.g. '#stdc' to include stdc.c
"                           if your current filetype is 'c'.
"
"                       g:CodeCompl_Template_Folder
"                           see paragraph above. the folder default is
"                           'templates'.
"
"                       g:CodeCompl_Complete_File
"                           file name of users defined snippets.  now
"                           it named 'my_snippets.template', use this
"                           postfix to prevent Vim load it
"                           automatically
"
"                       g:CodeCompl_ClearWhenUpdate
"                           see the Option section
"
"                       g:CodeCompl_SaveListInBuffer
"                           unused in current version
"
"
"                   global helper functions:
"                       
"                       MakeRegion
"                           same as g:CodeCompl_RegionStart . 'your
"                           text' . g:CodeCompl_RegionEnd, but input a
"                           little easily, but there are other helper
"                           function and variables in your complete
"                           file(defaults is my_snippets.template in
"                           your plugin folder)
"
"                       GetFileName
"                           get current file name as "__FOOBAR_H__",
"                           used in header file.
"
"                       SkipMarks
"                           skip the match to the marks in your
"                           snippets. used in "printf" snippet.
"
"                       GetInput
"                           let user input a string, you can use it
"                           later in your snippets, see the details in
"                           snippet "malloc" and "calloc".
"
"                       DefaultRegion
"                           the default region, just like
"                           g:CodeCompl_RegionStart."...".g:CodeCompl_RegionEnd
"
"
"                   default complete-words:
"                           see "my_snippets.template" file.
" }}}
" ========================================================================
" MUST after Vim 7.0 {{{1
" and check whether code_complete has been loaded
if &cp || v:version < 700 || exists('g:loaded_code_complete')
    finish
endif
let g:loaded_code_complete = "v2.8.1"
let s:keepcpo = &cpo
set cpo&vim

" }}}
" ------------------------------------------------------------------------
" pre-defined Commands and Menu {{{1


" you can input the command with tab, e.g: :Start<Tab>, it can be faster
command StartCodeComplele call <SID>CodeCompleteStart()
command StopCodeComplete call <SID>CodeCompleteStop()
command UpdateTemplate call <SID>TemplateUpdate()
command EditSnippets call <SID>SnippetFileEdit()
command -bang SaveAsTemplate call <SID>TemplateFileSave('<bang>')

" Menus:
menu <silent> &Tools.Code\ Complete.Start               :StartCodeComplele<CR>
menu <silent> &Tools.Code\ Complete.Stop                :StopCodeComplete<CR>
menu <silent> &Tools.Code\ Complete.Update\ Templates   :UpdateTemplate<CR>
menu <silent> &Tools.Code\ Complete.Edit\ Snippet\ File :EditSnippets<CR>
menu <silent> &Tools.Code\ Complete.Save\ As\ Template  :SaveAsTemplate<CR>
" }}}
" Options, define them as you like in vimrc {{{1
" (or remain it in default value.)

" Hotkey to call code_complete {{{2
" we don't use <tab>, for compatible with supertab.vim you
" can use the default key:ALT-D, you will find it's easy to
" press in a USA-Standard keyboard. if you don't use
" supertab or you wan't use the default key, you can
" redefine it.
if !exists('g:CodeCompl_Hotkey')
    let g:CodeCompl_Hotkey = "<a-d>"
endif

" }}}
" Some marks to use template And Some Global helpers {{{2
" the Region Start and End, you can use them to define
" youself mark. e.g. g:rs.'hello'.g:re in defalut, it looks
" as '`<hello>`', and if you press hotkey, your cursor will
" move to the word, and into the selection mode. you can
" redefine them, but must be careful, because file template
" use the same marks, if you change it, you must substitute
" all marks in your all template-file.
" e.g. a template file(you can named std.c and drop it in
" your template-folder):
" #define <stdio.h>
" int main(void)
" {
"     `<Input Code here>`
"     retnrn 0;
" }
"
" Region Start mark
if !exists("g:CodeCompl_RegionStart")
    let g:CodeCompl_RegionStart = '`<'
endif

" Region End mark
if !exists("g:CodeCompl_RegionEnd")
    let g:CodeCompl_RegionEnd = '>`'
endif

" Make Regions use marks above
function! MakeRegion(text)
    return g:CodeCompl_RegionStart . a:text . g:CodeCompl_RegionEnd
endfunction

" Define the marks in template files, they will be substituted by
" marks above.
" template file region Start mark
if !exists("g:CodeCompl_Template_RegionStart")
    let g:CodeCompl_Template_RegionStart = '__('
endif

" template file region End mark
if !exists("g:CodeCompl_Template_RegionEnd")
    let g:CodeCompl_Template_RegionEnd = ')__'
endif

" [Get converted file name like __THIS_FILE__ ]
function! GetFileName()
    let filename = toupper(expand('%:t'))
    let name = substitute(filename,'\.','_',"g")
    let name = "__".name."__"
    return name
endfunction

" don't highlight marks after completed
function! SkipMarks()
    let s:jumppos = -2
    return ''
endfunction

" Input for something
function! GetInput(string, var)
    if !exists('g:'.a:var)
        exec 'let g:'.a:var.'=""'
    endif

    echohl Search
    call inputsave()
    exec 'let g:'.a:var.'=input(a:string, g:'.a:var.')'
    call inputrestore()
    echohl None
    return ''
endfunction

" this is a default region, you must update it manually
let DefaultRegion = MakeRegion('...')

" }}}
" Fore-char for doing file complete {{{2
" if you input a Fore-char, code_complete will first try
" file complete, if failed code_complete will remain
" fore-char as it is. e.g. if you have a template file named
" std.c, and you type '#std<A-D>' in Vim(as default), it
" will be like this:
" #include <stdio.h>
"
" int main(void)
" {
"     |`<Input Code Here>`
"     return 0;
" }
" the cursor will be at the postion of '|', it is the same
" as you define this template-dictionary-list in complete
" file.
" if code_complete can't find the complate file, it will
" find keyword in complete file, so if you don't have a
" std.c file, but you have 'std' item in your complete file
" ('std':'/* this is a std text */'), when you type
" '#std<A-D>', it will be changed:
" #/* this is a std text */
" the fore-char '#' will be remain there.
if !exists('g:CodeCompl_Template_Forechar')
    let g:CodeCompl_Template_Forechar = '#'
endif


" }}}
" Modify when update dict, shall code_complete delete {{{2
" current dicts decide whether code_complete should delete
" old dict when update, e.g. open g:CodeCompl_SaveListInBuffer
" and change your file type.
"       0 means don't clean current dict
"       1 means clear all dict item, and reload immediately
if !exists('g:CodeCompl_ClearWhenUpdate')
    let g:CodeCompl_ClearWhenUpdate = 1
endif

" }}}
" Define where to save template file names and complete lists {{{2
" this decide where code_complete save the template list:
"       0 means save globe template list
"       1 means save buffer template list, and read file
"           when edit a new file or change filetype
if !exists('g:CodeCompl_SaveListInBuffer')
    let g:CodeCompl_SaveListInBuffer = 0
endif

" }}}
" User-defined complete file {{{2
" this tell code_complete where to find the templete file.
" it must be in &runtimepath, or a subfolder in it.
" you can use UpdateTemplate to re-read this file.
if !exists("g:CodeCompl_Complete_File")
    let g:CodeCompl_Complete_File = "plugin/my_snippets.template"
endif

" }}}
" User-defined template folder {{{2
" this tell code_complete where to find the template folder
" a template folder is a folder, every file is a template for
" special filetype, e.g. std.c is a template named 'std', and
" for c file, std.cpp is a template named 'std', buf for cpp 
" file. the folder must under the &runtimepath, or the subfolder
" of it.
" you can use UpdateTemplate to update it
if !exists("g:CodeCompl_Template_Folder")
    let g:CodeCompl_Template_Folder = "templates"
endif

" }}}
" Enable default complete file or not {{{2
" set g:Code_Compl_Enable_Default_Snippets to non-zero to enable the
" default snippets file, and set it to zero to disabled it.
if !exists("g:CodeCompl_Enable_Default_Snippets")
    let g:CodeCompl_Enable_Default_Snippets = 1
endif

" }}}
" Default complete file name {{{2
" define the default complete file's name.
if !exists("g:CodeCompl_Default_Complete_File")
    let g:CodeCompl_Default_Complete_File = "plugin/default_snippets.template"
endif

" }}}

" }}}
" Function Definations {{{1

" Start the code_complete, do some initialization work {{{2
"
function! <SID>CodeCompleteStart()
    " define the key maps use g:CodeCompl_Hotkey
    exec 'nnoremap <silent><buffer> '.g:CodeCompl_Hotkey.
                \ " :exec 'silent! normal '.<SID>SwitchRegion()<cr>"
    exec 'inoremap <silent><buffer> '.g:CodeCompl_Hotkey.
                \ ' <c-r>=<SID>CodeComplete()<cr>'.
                \ '<c-r>=<SID>SwitchRegion()<cr>'
    exec 'smap <silent><buffer> '.g:CodeCompl_Hotkey.
                \ ' <esc>'.g:CodeCompl_Hotkey

    " -----------------------------------
    " Some Inner variables

    " control the action of function SwitchRegion()
    " -1 means don't jump to anywhere, and -2 means do nothing
    let s:jumppos = -1

    " update template and complete file, if needed
    if g:CodeCompl_SaveListInBuffer
        call s:BufferTemplateUpdate()
    else
        let b:complete_FileList = get(s:complete_FileList, &ft,
                    \ s:complete_FileList['COMMON'])
        let b:complete_Snippets = get(s:complete_Snippets, &ft, 
                    \ s:complete_Snippets['COMMON'])
    endif
endfunction
" }}}
" End code, some clean work in here {{{2
"
function! <SID>CodeCompleteStop()
    " delete autocmds
    augroup code_complete
        au!
    augroup END
    " unmap all keys
    for ch in ['i', 's', 'n']
        exec 'silent! '.ch.'unmap <buffer> '.g:CodeCompl_Hotkey
    endfor

    " release some dictionary
    unlet! b:template_FileList
    unlet! b:template_Snippets
endfunction
" }}}
" Update template or complete file {{{2
"
function! <SID>TemplateUpdate()
    if g:CodeCompl_SaveListInBuffer
        call s:BufferTemplateUpdate()
    else
        call s:GlobalTemplateUpdate()
    endif
endfunction
" }}}
" Edit the Snippet file {{{2
"
function! <SID>SnippetFileEdit()
    let flist = globpath(&rtp, g:CodeCompl_Complete_File)
    for fname in split(flist, "\<NL>")
        exec 'drop'escape(fname, ' |')
        return
    endfor
endfunction
" }}}
" Save current file to template folder {{{2
"
function! <SID>TemplateFileSave(bang)
    let tdir = globpath(&rtp, g:CodeCompl_Template_Folder)
    let second_dir = stridx(tdir, "\<NL>")
    if second_dir != -1
        let tdir = tdir[:second_file - 1]
    endif
    let ft = empty(&ft) ? '' : '.'.&ft
    exec 'write'.a:bang.' '.tdir.'/'.exoand('%:t:r').ft
    let b:complete_FileList[expand('%:t:r')] = expand('%:p')
    if g:CodeCompl_SaveListInBuffer && empty(ft)
        let s:complete_FileList['COMMON'][expand('%:t:r')] = expand('%:p')
    endif
endfunction
" }}}
" Update global templates and completes {{{2
"
function! s:GlobalTemplateUpdate()
    " init dictionarys
    if g:CodeCompl_ClearWhenUpdate || !exists('s:complete_FileList')
        let s:complete_FileList = {}
    endif
    if g:CodeCompl_ClearWhenUpdate || !exists('s:complete_Snippets')
        let s:complete_Snippets = {}
    endif
    if !has_key(s:complete_FileList, 'COMMON')
        let s:complete_FileList['COMMON'] = {}
    endif
    if !has_key(s:complete_Snippets, 'COMMON')
        let s:complete_Snippets['COMMON'] = {}
    endif

    " search for template file list
    let flist = split(globpath(&rtp, g:CodeCompl_Template_Folder.'/*'), "\<NL>")

    for fname in flist
        let ft = fnamemodify(fname, ':t:e')
        let ft = empty(ft) ? 'COMMON' : ft
        let key = fnamemodify(fname, ':t:r')
        if !has_key(s:complete_FileList, ft)
            let s:complete_FileList[ft] = {}
        endif
        let s:complete_FileList[ft][key] = fname
    endfor

    " call the template defined file
    let flist = [g:CodeCompl_Complete_File]

    if g:CodeCompl_Enable_Default_Snippets
        let flist += [g:CodeCompl_Default_Complete_File]
    endif

    for cfile in flist

        exec "runtime ".cfile
        redir => output
        silent function /^Set_complete_type_.*$/
        redir END

        if empty(output)
            continue
        endif

        let func_list = split(output, "\<NL>")

        for func in func_list
            let func = matchstr(func, '^function \zsSet_complete_type_[^(]\+\ze')
            let ft = matchstr(func, '^Set_complete_type_\zs.*\ze$')
            if !has_key(s:complete_Snippets, ft)
                let s:complete_Snippets[ft] = {}
            endif
            if !has_key(s:complete_FileList, ft)
                let s:complete_FileList[ft] = {}
            endif

            exec 'call '.func.'(s:complete_Snippets[ft], '.
                        \ 's:complete_FileList[ft])'
        endfor

        for func in func_list
            let func = matchstr(func, '^function \zsSet_complete_type_[^(]\+\ze')
            exec 'delfunction '.func
        endfor

    endfor

    let b:complete_FileList = get(s:complete_FileList, &ft,
                \ s:complete_FileList['COMMON'])
    let b:complete_Snippets = get(s:complete_Snippets, &ft, 
                \ s:complete_Snippets['COMMON'])

endfunction
" }}}
" Update buffer templates and completes {{{2
" 
function! s:BufferTemplateUpdate()
    " init dictionarys
    if g:CodeCompl_ClearWhenUpdate || !exists('b:complete_FileList')
        let b:complete_FileList = {}
    endif
    if g:CodeCompl_ClearWhenUpdate || !exists('b:complete_Snippets')
        let b:complete_Snippets = {}
    endif

    " search for template file list
    let flist = split(globpath(&rtp, g:CodeCompl_Template_Folder.'/*'),
                \ "\<NL>")
    let ft_pat = empty(&ft) ? '^[^.]*$' : '^[^.]\+\%(\.'.&ft.'\)\=$'
    for fname in filter(flist, "v:val =~ '".ft_pat."'")
        let b:complete_FileList[fnamemodify(fname, ':t:r')] = fname
    endfor

    " call the template defined file
    let flist = [g:CodeCompl_Complete_File]

    if g:CodeCompl_Enable_Default_Snippets
        let flist += [g:CodeCompl_Default_Complete_File]
    endif

    for cfile in flist

        exec "runtime ".cfile
        if exists("*Set_complete_type_COMMON")
            silent! call Set_complete_type_COMMON(b:complete_Snippets,
                        \  b:complete_FileList)
        endif
        if !empty(&ft) && exists("*Set_complete_type_".&ft)
            silent! call Set_complete_type_{&ft}(b:complete_Snippets,
                        \ b:complete_FileList)
        endif

        " delete all function in complete file
        redir => func_list
        silent function /^Set_complete_type_.*$/
        redir END

        if !empty(func_list)
            for func in split(func_list, "\<NL>")
                exec 'delfunction '.matchstr(func,
                            \ '^function \zsSet_complete_type_[^(]\+\ze')
            endfor
        endif

    endfor
endfunction
" }}}
" Complete, use commplete dict {{{2
" find the word in complete dictionary
function! s:SnippetsComplete(cword)
    let value = get(b:complete_Snippets, a:cword, '')
    if empty(value) && !g:CodeCompl_SaveListInBuffer 
        let value = get(s:complete_Snippets['COMMON'], a:cword, '')
    endif
    if !empty(value)
        let s:jumppos = line('.')
    endif
    return value
endfunction
" }}}
" Complete template file {{{2
" function return 0 if it have found a template, and if it failed, it
" return 1.
function! s:TemplateComplete(cword)
    let fname = get(b:complete_FileList, a:cword, '')

    if empty(fname) && !g:CodeCompl_SaveListInBuffer
        let fname = get(s:complete_FileList['COMMON'], a:cword, '')
    endif

    if empty(fname)
        return 1
    endif

    let s:jumppos = -1
    let line = line('.')
    let template = join(readfile(fname), "\<NL>")
    let template = substitute(template, 
                \ escape(g:CodeCompl_Template_RegionStart,'\').'\([^\n]\{-}\)'.
                \ escape(g:CodeCompl_Template_RegionEnd,'\'), 
                \ escape(g:CodeCompl_RegionStart,'&').'\1'.
                \ escape(g:CodeCompl_RegionEnd,'&'),'g')

    let tlist = split(template, "\<NL>")
    call setline(line, tlist[0])
    call append(line, tlist[1:])
    call cursor(line, 1)
endfunction
" }}}
" Some process to signature {{{2
"
function! s:ProcessSignature(sig)
    let res = g:CodeCompl_RegionStart
    let level = 0
    for ch in split(substitute(a:sig[1:-2],'\s*,\s*',',','g'), '\zs')
        if ch == ','
            if level != 0
                let res .= ', '
            else
                let res .= g:CodeCompl_RegionEnd.', '.g:CodeCompl_RegionStart
            endif
        else
            let res .= ch
            let level += (ch == '(' ? 1 : (ch == ')' ? -1 : 0 ))
        endif
    endfor
    return res.g:CodeCompl_RegionEnd.')'.MakeRegion(';')
endfunction
" }}}
" Complete function argument list {{{2
" 
function! s:FunctionComplete(fun)
    let sig_list = []
    let sig_word = {}
    let ftags = taglist('^'.a:fun.'$')

    " if can't find the function
    if type(ftags) == type(0) || empty(ftags)
        return ''
    endif

    for item in ftags
        " item must have keys kind, name and signature, and must be the
        " type of p(declare) or f(defination), function name must be same
        " with a:fun, and must have param-list
        " if any reason can't satisfy, to next iteration
        if !has_key(item, 'kind') || (item.kind != 'p' && item.kind != 'f')
                    \ || !has_key(item, 'name') || item.name != a:fun
                    \ || !has_key(item, 'signature')
                    \ || match(item.signature, '^(\s*\%(void\)\=\s*)$') >= 0
            continue
        endif
        let sig = s:ProcessSignature(item.signature)
        if !has_key(sig_word, sig)
            let sig_word[sig] = 0
            let sig_list += [{'word': sig, 'menu': item.filename}]
        endif
    endfor

    " only one list find, that is we need!
    if len(sig_list) == 1
        let s:jumppos = line('.')
        return sig_list[0].word
    endif

    let s:jumppos = -2

    " can't find the argument-list, means it's a void function
    if empty(sig_list)
        return ')'
    endif

    " make a complete menu
    call complete(col('.'), sig_list)
    " tell SwitchRegion do nothing
    return ''
endfunction
" }}}
" Switch the Region to edit {{{2
"
function! <SID>SwitchRegion()
    " sometimes we don't do anything...
    if s:jumppos == -2
        let s:jumppos = -1
        return ''
    endif
    let flags = ''
    let c_pos = getpos('.')

    " if call Complete function once, set cursor to that line.
    if s:jumppos != -1
        call cursor(s:jumppos, 1)
        let flags = 'c'
        let s:jumppos = -1
    endif

    " return empty string when can't find the token IN SCREEN
    " and around 100 line of file.
    let token = MakeRegion('.\{-}')
    if search(token, flags, line('w$') + 100) == 0
        call cursor(line('w0') > 100 ? line('w0') - 100 : 1, 1)
        if search(token, '', c_pos[1]) == 0
            call setpos('.', c_pos)
            return ''
        endif
    endif

    call search(g:CodeCompl_RegionStart, 'c')
    exec "normal! \<c-\>\<c-n>v"
    call search(g:CodeCompl_RegionEnd,'e',line('.'))
    if &selection == "exclusive"
        normal! l
    endif
    return "\<c-\>\<c-n>gvo\<c-g>"
endfunction
" }}}
" Complete function, called each sub-function {{{2
"
function! <SID>CodeComplete()
    " fore-char
    let fc = g:CodeCompl_Template_Forechar
    " current-line
    let c_line = getline('.')[:col('.') - 2]
    " get the template name of function name
    let plist = matchlist(c_line, '\('.fc.'\s*\)\=\(\w*\)\s*\((\)\=\s*$')

    " if it's empty or is a template name
    if empty(plist) || empty(plist[2]) 
                \ || (!empty(plist[1]) && !s:TemplateComplete(plist[2]))
        return ''
    endif

    " else, if it's a function name
    if !empty(plist[3]) 
        return s:FunctionComplete(plist[2])
    endif

    " if can't find as a template, we find it with
    " complete-file. and if it can't find else, we find it
    " in template(if we don't do it before), all above
    " operations, if we can't find it at last, return empty
    " string.
    if !exists('result') || empty(result)
        let result = s:SnippetsComplete(plist[2])
        if !empty(result)
            return "\<c-w>".result
        endif
        if empty(plist[1]) && !s:TemplateComplete(plist[2])
            return ''
        endif
    endif

    return g:CodeCompl_Hotkey ==? "<tab>" ? "\<tab>" : ''
endfunction
" }}}

" }}}
" ------------------------------------------------------------------------
" Some Initialization works {{{

" define autocommands
augroup code_complete
    au!

    autocmd BufReadPost * StartCodeComplele
    autocmd BufNewFile * StartCodeComplele
    autocmd FileType * StartCodeComplele
augroup END


" Load template settings
if !g:CodeCompl_SaveListInBuffer
    call s:GlobalTemplateUpdate()
endif

" ensure the start function must be called when start vim
StartCodeComplele

let &cpo = s:keepcpo
unlet! s:keepcpo

" }}}
" vim: ft=vim:ff=unix:fdm=marker:tw=70:sts=4:ts=4:sw=4:et
