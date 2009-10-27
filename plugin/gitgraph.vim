
function! GitFolder(lnum)
    let regex = '\([0-9][|] \)* [*] '
    let bline = matchstr(getline(a:lnum-1), regex)
    let aline = matchstr(getline(a:lnum+1), regex)
    let line = matchstr(getline(a:lnum), regex)
    "echo "<".bline . "> - <" . line . "> - <" . aline .">"
    return bline ==# line && aline ==# line
endfunction

function! s:GitGraph() 
    set ma
    1,$delete
    read !git log --graph --decorate --format=oneline --abbrev-commit --color --all
    %s/\*\( \+\)/ *\1/ge
    %s/\[3\([0-9]\)m\([\|/]\)\[m/\1\2/ge
    %s/\[[0-9]*m//ge
    g/tag: refs\/tags\//s/tag: refs\/tags\//tag:/ge
    g/refs\/remotes\//s/refs\/remotes\//remote:/ge
    g/refs\/heads/s/refs\/heads\///ge
    goto 1 | delete
    setl ft=gitgraph fde=GitFolder(v:lnum) fdm=expr nowrap noma nomod
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

command! GitGraph :call <SID>GitGraph()
command! -nargs=? -range GitRebase :call <SID>GitRebase(<line1>, <line2>, <args>)
command! GitDelete :call <SID>GitDelete(expand('<cWORD>'), <SID>GetSynName('.', '.'))
command! GitPush :call <SID>GitPush(expand('<cWORD>'), <SID>GetSynName('.', '.'))

map <buffer> dw :GitDelete<cr>
map <buffer> ,gg :GitGraph<cr><cr>
map <buffer> ,gp :GitPush<cr><cr>
vmap <buffer> ,gr :GitRebase <space>
vmap <buffer> ,gri :GitRebase "-i"<cr>

