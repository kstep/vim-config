
function! GitFolder(lnum)
    let regex = '\([0-9][|] \)* [*] '
    let bline = matchstr(getline(a:lnum-1), regex)
    let aline = matchstr(getline(a:lnum+1), regex)
    let line = matchstr(getline(a:lnum), regex)
    "echo "<".bline . "> - <" . line . "> - <" . aline .">"
    return bline ==# line && aline ==# line
endfunction

function! GitBranchCompleter(arg, cline, cpos)
    let cmd = 'git branch | cut -c 3-'
    let lst = system(cmd)
    return lst
endfunction

" a:1 - branch, a:2 - order, a:3 - file
function! s:GitGraph(...) 
    let branch = exists('a:1') && a:1 != '' ? a:1 : ''
    let order = exists('a:2') && a:2 ? 'date' : 'topo'
    let afile = exists('a:3') && a:3 != '' ? a:3 : ''

    if bufname('%') =~# '^\[Git Graph\]'
        if afile == '' | let afile = b:gitgraph_file | endif
        if branch == '' | let branch = b:gitgraph_branch | endif
        set ma
        1,$delete
    else
        new
        file [Git\ Graph]
        let b:gitgraph_file = afile
        let b:gitgraph_branch = branch
        au ColorScheme <buffer> setl ft=gitgraph
        call s:GitMappings()
    endif

    let cmd = "0read !git log --graph --decorate=full --format=format:'\\%Creset\\%h\\%d [\\%aN] \\%s' --abbrev-commit --color --" . order . "-order " . branch . " -- " . afile
    exec cmd

    silent! %s/\*\( \+\)/ *\1/ge
    silent! %s/\[3\([0-9]\)m\([\|/]\)\[m/\1\2/ge
    silent! %s/\[[0-9]*m//ge

    silent! g/refs\/tags\//s/\(tag: \)\?refs\/tags\//tag:/ge
    silent! g/refs\/remotes\//s/refs\/remotes\//remote:/ge
    silent! g/refs\/heads/s/refs\/heads\///ge
    silent! g/refs\/stash/s/refs\/stash/stash/ge

    goto 1
    setl bt=nofile bh=delete ft=gitgraph fde=GitFolder(v:lnum) fdm=expr nowrap noma nomod noswf
endfunction

" a:000 - additional params
function! s:GitRebase(l1, l2, ...)
    let fcomm = matchstr(getline(a:l1), "[a-f0-9]\\{7,40}")
    let tcomm = matchstr(getline(a:l2), "[a-f0-9]\\{7,40}")
    if fcomm != "" && tcomm != ""
        let branch = "rebase-branch-" . fcomm
        exec "!git branch " . branch . " " . fcomm . " && git rebase " . join(a:000, " ") . " " . tcomm . " " . branch
        call s:GitGraph()
    endif
endfunction

" a:000 - additional params
function! s:GitDiff(l1, l2, ...)
    let fcomm = matchstr(getline(a:l1), "[a-f0-9]\\{7,40}")
    let tcomm = matchstr(getline(a:l2), "[a-f0-9]\\{7,40}")
    if fcomm != "" && tcomm != ""
        if fcomm == tcomm | let tcomm = "" | endif
        new
        exec "0read !git diff " . join(a:000, " ") . " " . tcomm . " " . fcomm
        setl ft=diff noma nomod
    endif
endfunction

function! s:GetSynName(l, c)
    return synIDattr(synID(line(a:l), col(a:c), 1), 'name')
endfunction

" a:1 - force
function! s:GitPush(word, syng, ...)
    let word = substitute(a:word, '[^:a-zA-Z0-9_/-]', '', 'g')
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(word[7:], "/")
        let force = exists("a:1") && a:1 ? " -f " : ""
        exec "!git push " . force . " " . parts[0] . " " . join(parts[1:], "/")
        call s:GitGraph()
    endif
endfunction

function! s:GitCheckout(word, syng)
    let word = substitute(a:word, '[^:a-zA-Z0-9_/-]', '', 'g')
    if a:syng == 'gitgraphRefItem'
        exec "!git checkout " . word
    endif
endfunction

function! s:GitPull(word, syng)
    let word = substitute(a:word, '[^:a-zA-Z0-9_/-]', '', 'g')
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(word[7:], "/")
        exec "!git pull " . parts[0] . " " . join(parts[1:], "/")
        call s:GitGraph()
    endif
endfunction

" a:1 - force
function! s:GitDelete(word, syng, ...)
    let force = exists("a:1") && a:1
    let word = substitute(a:word, '[^:a-zA-Z0-9_/-]', '', 'g')
    if a:syng == 'gitgraphRefItem'
        let par = force ? "-D" : "-d"
        let cmd = "!git branch " . par . " " . word
    elseif a:syng == 'gitgraphTagItem'
        let cmd = "!git tag -d " . word[4:]
    elseif a:syng == 'gitgraphRemoteItem'
        let par = force ? "-f" : ""
        let parts = split(word[7:], "/")
        let cmd = "!git push " . par . " " . parts[0] . " " . join(parts[1:], "/") . ":"
    else
        return
    endif
    exec cmd
    "echo cmd
    call s:GitGraph()
endfunction

function! s:GitSVNRebase(word, syng)
    call s:GitCheckout(a:word, a:syng)
    exec "!git svn rebase"
    call s:GitGraph()
endfunction

function! s:GitSVNDcommit(word, syng)
    call s:GitCheckout(a:word, a:syng)
    exec "!git svn dcommit"
    call s:GitGraph()
endfunction

function! s:GitMappings()
    command! -buffer -nargs=* -range GitRebase :call <SID>GitRebase(<line1>, <line2>, <f-args>)
    command! -buffer -nargs=* -range GitDiff :call <SID>GitDiff(<line1>, <line2>, <f-args>)
    command! -buffer -nargs=? GitDelete :call <SID>GitDelete(expand('<cWORD>'), <SID>GetSynName('.', '.'), <f-args>)

    command! -buffer -nargs=? GitPush :call <SID>GitPush(expand('<cWORD>'), <SID>GetSynName('.', '.'), <f-args>)
    command! -buffer GitPull :call <SID>GitPull(expand('<cWORD>'), <SID>GetSynName('.', '.'))
    command! -buffer GitCheckout :call <SID>GitCheckout(expand('<cWORD>'), <SID>GetSynName('.', '.'))

    command! -buffer GitSVNRebase :call <SID>GitSVNRebase(expand('<cWORD>'), <SID>GetSynName('.', '.'))
    command! -buffer GitSVNDcommit :call <SID>GitSVNDcommit(expand('<cWORD>'), <SID>GetSynName('.', '.'))

    map <buffer> dw :GitDelete<cr>
    map <buffer> ,gp :GitPush<cr><cr>
    map <buffer> ,gu :GitPull<cr><cr>
    map <buffer> ,gc :GitCheckout<cr><cr>

    vmap <buffer> ,gr :GitRebase<space>
    vmap <buffer> ,gri :GitRebase "-i"<cr>
    vmap <buffer> ,gd :GitDiff<cr><cr>

    map <buffer> ,su :GitSVNRebase<cr><cr>
    map <buffer> ,sp :GitSVNDcommit<cr><cr>
endfunction

command! -nargs=* -complete=custom,GitBranchCompleter GitGraph :call <SID>GitGraph(<f-args>)

map ,gg :GitGraph "--all"<cr><cr>
map ,gf :exec 'GitGraph "--all" 0 '.expand('%:p')<cr><cr>

