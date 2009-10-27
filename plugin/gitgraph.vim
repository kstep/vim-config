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
    setl ft=gitgraph noma nomod
endfunction

function! s:GitRebase(pars)
    let l:fcomm = matchstr(getline("'<"), "[a-f0-9]\\{6,40}")
    let l:tcomm = matchstr(getline("'>"), "[a-f0-9]\\{6,40}")
    if l:fcomm != "" && l:tcomm != ""
        let l:branch = "rebase-branch-" . l:fcomm
        exec "!git branch " . l:branch . " " . l:fcomm . " && git rebase " . a:pars . " " . l:tcomm . " " . l:branch
        "quit!
        call s:GitGraph()
    endif
endfunction

function! GitDelete()
    let l:word = substitute(expand('<cWORD>'), '[^:a-zA-Z0-9_/-]', '', 'g')
    let l:synname = synIDattr(synID(line('.'), col('.'), 1), 'name')
    if l:synname == 'gitgraphRefItem'
        let l:cmd = "!git branch -d " . l:word
    elseif l:synname == 'gitgraphTagItem'
        let l:cmd = "!git tag -d " . l:word[4:]
    elseif l:synname == 'gitgraphRemoteItem'
        let l:parts = split(l:word[7:], "/")
        let l:cmd = "!git push " . l:parts[0] . " " . join(l:parts[1:], "/") . ":"
    endif
    exec l:cmd
endfunction

command! GitGraph :call <SID>GitGraph()
command! -nargs=1 GitRebase :call <SID>GitRebase(<args>)

noremap ,gg :GitGraph<cr><cr>
vnoremap ,gr <esc>:GitRebase ""<space>
vnoremap ,gri <esc>:GitRebase "-i"<cr>
