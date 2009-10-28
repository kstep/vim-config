
function! GitFolder(lnum)
    let regex = '\([0-9][|] \)* [*] '
    let bline = matchstr(getline(a:lnum-1), regex)
    let aline = matchstr(getline(a:lnum+1), regex)
    let line = matchstr(getline(a:lnum), regex)
    "echo "<".bline . "> - <" . line . "> - <" . aline .">"
    return bline ==# line && aline ==# line
endfunction

" a:0 - branch, a:1 - order
function! s:GitGraph(...) 
    if bufname("%") ==# "[Git Graph]"
        set ma
        1,$delete
    else
        new
        file [Git\ Graph]
        call s:GitMappings()
    endif

    let order = exists("a:2") && a:2 ? "date" : "topo"
    let branch = exists("a:1") && a:1 != "" ? a:1 : "\--all"
    let cmd = "read !git log --graph --decorate --format=oneline --abbrev-commit --color --" . order . "-order " . branch
    exec cmd

    %s/\*\( \+\)/ *\1/ge
    %s/\[3\([0-9]\)m\([\|/]\)\[m/\1\2/ge
    %s/\[[0-9]*m//ge

    g/refs\/tags\//s/\(tag: \)\?refs\/tags\//tag:/ge
    g/refs\/remotes\//s/refs\/remotes\//remote:/ge
    g/refs\/heads/s/refs\/heads\///ge

    goto 1 | delete

    setl bt=nofile bh=delete ft=gitgraph fde=GitFolder(v:lnum) fdm=expr nowrap noma nomod noswf
endfunction

function! s:GitRebase(l1, l2, ...)
    let fcomm = matchstr(getline(a:l1), "[a-f0-9]\\{7,40}")
    let tcomm = matchstr(getline(a:l2), "[a-f0-9]\\{7,40}")
    if fcomm != "" && tcomm != ""
        let branch = "rebase-branch-" . fcomm
        exec "!git branch " . branch . " " . fcomm . " && git rebase " . join(a:000, " ") . " " . tcomm . " " . branch
        call s:GitGraph()
    endif
endfunction

function! s:GitDiff(l1, l2, ...)
    let fcomm = matchstr(getline(a:l1), "[a-f0-9]\\{7,40}")
    let tcomm = matchstr(getline(a:l2), "[a-f0-9]\\{7,40}")
    if fcomm != "" && tcomm != ""
        new
        exec "read !git diff " . join(a:000, " ") . " " . tcomm . " " . fcomm
        setl ft=diff noma nomod
    endif
endfunction

function! s:GetSynName(l, c)
    return synIDattr(synID(line(a:l), col(a:c), 1), 'name')
endfunction

function! s:GitPush(word, syng)
    let word = substitute(a:word, '[^:a-zA-Z0-9_/-]', '', 'g')
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(word[7:], "/")
        exec "!git push " . parts[0] . " " . join(parts[1:], "/")
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

function! s:GitDelete(word, syng)
    let word = substitute(a:word, '[^:a-zA-Z0-9_/-]', '', 'g')
    if a:syng == 'gitgraphRefItem'
        let cmd = "!git branch -d " . word
    elseif a:syng == 'gitgraphTagItem'
        let cmd = "!git tag -d " . word[4:]
    elseif a:syng == 'gitgraphRemoteItem'
        let parts = split(word[7:], "/")
        let cmd = "!git push " . parts[0] . " " . join(parts[1:], "/") . ":"
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
    command! -buffer -nargs=? -range GitRebase :call <SID>GitRebase(<line1>, <line2>, <args>)
    command! -buffer -nargs=? -range GitDiff :call <SID>GitDiff(<line1>, <line2>, <args>)
    command! -buffer GitDelete :call <SID>GitDelete(expand('<cWORD>'), <SID>GetSynName('.', '.'))
    command! -buffer GitPush :call <SID>GitPush(expand('<cWORD>'), <SID>GetSynName('.', '.'))
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

command! -nargs=* GitGraph :call <SID>GitGraph(<args>)

map ,gg :GitGraph<cr><cr>

