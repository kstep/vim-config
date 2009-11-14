
function! s:GitGetRepository()
    let reponame = system('git rev-parse --git-dir')[:-2]
    if reponame ==# '.git'
        let reponame = getcwd()
    else
        let reponame = fnamemodify(reponame, ':h')
    endif
    return reponame
endfunction

function! GitGraphFolder(lnum)
    let regex = '\([0-9][|] \)* [*] '
    let bline = matchstr(getline(a:lnum-1), regex)
    let aline = matchstr(getline(a:lnum+1), regex)
    let line = matchstr(getline(a:lnum), regex)
    "echo "<".bline . "> - <" . line . "> - <" . aline .">"
    return bline ==# line && aline ==# line
endfunction

function! GitDiffGotoFile(fname)
    let repopath = s:GitGetRepository()
    let fname = a:fname
    if fname =~# "^[ab]/" | let fname = fname[2:] | endif
    if repopath != "" | let fname = repopath . "/" . fname | endif
    return fname
endfunction

function! s:GitGraphBranchCompleter(arg, cline, cpos)
    let cmd = 'git branch | cut -c 3-'
    let lst = system(cmd)
    return lst
endfunction

function! s:GitGraphInit()
    if !exists('g:gitgraph_date_format') || g:gitgraph_date_format == ''
        let g:gitgraph_date_format = "short"
    end

    if !exists('g:gitgraph_authorship_format') || g:gitgraph_authorship_format == ''
        let g:gitgraph_authorship_format = '%aN, %ad'
    end

    if !exists('g:gitgraph_subject_format') || g:gitgraph_subject_format == ''
        let g:gitgraph_subject_format = '%s'
    end

    let s:gitgraph_graph_format = shellescape('%Creset%h%d ' . g:gitgraph_subject_format . ' [' . g:gitgraph_authorship_format . ']', '%')

    command! -nargs=* -complete=custom,<SID>GitGraphBranchCompleter GitGraph :call <SID>GitGraph(<f-args>)

    map ,gg :GitGraph "--all"<cr><cr>
    map ,gf :exec 'GitGraph "--all" 0 '.expand('%:p')<cr><cr>
endfunction

function! s:GitGraphNew(branch, afile)
    let reponame = fnamemodify(s:GitGetRepository(), ':t')
    new
    exec 'file [Git\ Graph:' . reponame . ']'
    let b:gitgraph_file = a:afile
    let b:gitgraph_branch = a:branch
    au ColorScheme <buffer> setl ft=gitgraph | call s:GitGraphMarkHead()
    call s:GitGraphMappings()
endfunction

function! s:GitGraphMarkHead()
    let commit = system('git rev-parse --short HEAD')[:-2]
    let branch = system('git symbolic-ref -q HEAD')[11:-2]
    silent! syn clear gitgraphHeadRefItem
    exec 'syn keyword gitgraphHeadRefItem ' . commit . ' ' . branch . ' contained'
endfunction

" a:1 - branch, a:2 - order, a:3 - file
function! s:GitGraph(...)
    let branch = exists('a:1') && a:1 != '' ? a:1 : ''
    let order = exists('a:2') && a:2 ? 'date' : 'topo'
    let afile = exists('a:3') && a:3 != '' ? a:3 : ''

    if bufname('%') =~# '^\[Git Graph'
        if afile == '' | let afile = b:gitgraph_file | endif
        if branch == '' | let branch = b:gitgraph_branch | endif
    else
        call s:GitGraphNew(branch, afile)
    endif

    let cmd = "0read !git log --graph --decorate=full --date=" . g:gitgraph_date_format . " --format=format:" . s:gitgraph_graph_format . " --abbrev-commit --color --" . order . "-order " . branch . " -- " . afile
    set ma
    1,$delete
    exec cmd

    silent! %s/\*\( \+\)/ *\1/ge
    silent! %s/\[3\([0-9]\)m\([\|/_]\)\[m/\1\2/ge
    silent! %s/\[[0-9]*m//ge

    silent! g/refs\/tags\//s/\(tag: \)\?refs\/tags\//tag:/ge
    silent! g/refs\/remotes\//s/refs\/remotes\//remote:/ge
    silent! g/refs\/heads/s/refs\/heads\///ge
    silent! g/refs\/stash/s/refs\/stash/stash/ge

    goto 1

    setl bt=nofile bh=delete ft=gitgraph fde=GitGraphFolder(v:lnum) isk=:,a-z,A-Z,48-57,.,_,-,/ fdm=expr nowrap noma nomod noswf cul
    call s:GitGraphMarkHead()
endfunction

function! s:GetLineCommit(line)
    return matchstr(getline(a:line), '\<[a-f0-9]\{7,40}\>')
endfunction

function! s:GitBranch(commit, branch)
    if a:branch != ""
        exec "!git branch " . shellescape(a:branch) . " " . a:commit
        call s:GitGraph()
    endif
endfunction

function! s:GitTag(commit, tag, ...)
    if a:tag != ""
        exec "!git tag " . join(a:000, " ") . " " . shellescape(a:tag) . " " . a:commit
        call s:GitGraph()
    endif
endfunction

function! s:GitMerge(tobranch, frombranch, ...)
    if a:tobranch != "" && a:frombranch != ""
        exec "!git checkout " . shellescape(a:tobranch) . " && git merge " . join(a:000, " ") . " " . shellescape(a:frombranch)
        call s:GitGraph()
    endif
endfunction

" a:000 - additional params
function! s:GitRebase(fcomm, tcomm, ...)
    if a:fcomm != "" && a:tcomm != ""
        let branch = "rebase-branch-" . a:fcomm
        exec "!git branch " . branch . " " . a:fcomm . " && git rebase " . join(a:000, " ") . " " . a:tcomm . " " . branch
        call s:GitGraph()
    endif
endfunction

function! s:Scratch(bufname, size, cmd)
    let bufpat = "^".escape(a:bufname, "[]*+")."$"
    let bufno = bufnr(bufpat)
    if bufno == -1
        new
        exec a:size."wincmd _"
        setl noswf bt=nofile bh=hide
        exec "file " . escape(a:bufname, " ")
    else
        let winno = bufwinnr(bufno)
        if winno == -1
            exec "split +buffer" . bufno
            exec a:size."wincmd _"
        elseif winno != winnr()
            exec winno."wincmd w"
        endif
    endif

    if a:cmd != ''
        setl ma
        exec a:cmd
        setl noma nomod
    endif
    goto 1
endfunction

" a:000 - additional params
function! s:GitDiff(fcomm, tcomm, ...)
    if a:fcomm != "" && a:tcomm != ""
        let cmd = "0read !git diff " . join(a:000, " ") . " " . a:tcomm
        if a:fcomm != a:tcomm | let cmd = cmd . " " . a:fcomm | endif
        call s:Scratch("[Git Diff]", 15, cmd)
        setl ft=diff inex=GitDiffGotoFile(v:fname)
        map <buffer> <C-d> /^commit [0-9a-f]\+<CR>
        map <buffer> <C-u> ?^commit [0-9a-f]\+<CR>
    endif
endfunction

function! s:GitShow(commit, ...)
    if a:commit != ""
        let cmd = "0read !git show " . join(a:000, " ") . " " . a:commit
        call s:Scratch("[Git Show]", 15, cmd)
        setl ft=diff.gitlog inex=GitDiffGotoFile(v:fname)
        map <buffer> <C-d> /^commit [0-9a-f]\+<CR>
        map <buffer> <C-u> ?^commit [0-9a-f]\+<CR>
    endif
endfunction

function! s:GetSynName(l, c)
    return synIDattr(synID(line(a:l), col(a:c), 1), 'name')
endfunction

function! s:GetRefName(word)
    return substitute(a:word, '[^:a-zA-Z0-9_/-]', '', 'g')
endfunction

" a:1 - force
function! s:GitPush(word, syng, ...)
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(a:word[7:], "/")
        let force = exists("a:1") && a:1 ? " -f " : ""
        exec "!git push " . force . " " . parts[0] . " " . join(parts[1:], "/")
        call s:GitGraph()
    endif
endfunction

function! s:GitCheckout(word, syng)
    if a:syng == 'gitgraphRefItem'
        exec "!git checkout " . a:word
        call s:GitGraphMarkHead()
    endif
endfunction

function! s:GitPull(word, syng)
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(a:word[7:], "/")
        exec "!git pull " . parts[0] . " " . join(parts[1:], "/")
        call s:GitGraph()
    endif
endfunction

" a:1 - force
function! s:GitDelete(word, syng, ...)
    let force = exists("a:1") && a:1
    if a:syng == 'gitgraphRefItem'
        let par = force ? "-D" : "-d"
        let cmd = "!git branch " . par . " " . a:word
    elseif a:syng == 'gitgraphTagItem'
        let cmd = "!git tag -d " . a:word[4:]
    elseif a:syng == 'gitgraphRemoteItem'
        let par = force ? "-f" : ""
        let parts = split(a:word[7:], "/")
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

function! s:GitGraphMappings()
    command! -buffer -nargs=* -range GitRebase :call <SID>GitRebase(<SID>GetLineCommit(<line1>), <SID>GetLineCommit(<line2>), <f-args>)
    command! -buffer -nargs=* -range GitDiff :call <SID>GitDiff(<SID>GetLineCommit(<line1>), <SID>GetLineCommit(<line2>), <f-args>)
    command! -buffer GitShow :call <SID>GitShow(<SID>GetLineCommit('.'))

    command! -buffer -nargs=? GitDelete :call <SID>GitDelete(<SID>GetRefName(expand('<cWORD>')), <SID>GetSynName('.', '.'), <f-args>)
    command! -buffer GitBranch :call <SID>GitBranch(<SID>GetLineCommit('.'), input("Enter new branch name: "))
    command! -buffer GitTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "))
    command! -buffer GitSignedTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "), "-s")
    command! -buffer GitAnnTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "), "-a")

    command! -buffer -nargs=? GitPush :call <SID>GitPush(<SID>GetRefName(expand('<cWORD>')), <SID>GetSynName('.', '.'), <f-args>)
    command! -buffer GitPull :call <SID>GitPull(<SID>GetRefName(expand('<cWORD>')), <SID>GetSynName('.', '.'))
    command! -buffer GitCheckout :call <SID>GitCheckout(<SID>GetRefName(expand('<cWORD>')), <SID>GetSynName('.', '.'))

    command! -buffer GitSVNRebase :call <SID>GitSVNRebase(<SID>GetRefName(expand('<cWORD>')), <SID>GetSynName('.', '.'))
    command! -buffer GitSVNDcommit :call <SID>GitSVNDcommit(<SID>GetRefName(expand('<cWORD>')), <SID>GetSynName('.', '.'))

    " (d)elete (w)ord
    map <buffer> dw :GitDelete<cr>

    map <buffer> ,gp :GitPush<cr><cr>
    map <buffer> ,gu :GitPull<cr><cr>
    map <buffer> ,gc :GitCheckout<cr><cr>

    " (a)dd (b)ranch, (t)ag, (a)nnotated/(s)igned tag
    map <buffer> ab :GitBranch<cr>
    map <buffer> at :GitTag<cr>
    map <buffer> aa :GitAnnTag<cr>
    map <buffer> as :GitSignedTag<cr>

    vmap <buffer> ,gr :GitRebase<space>
    vmap <buffer> ,gri :GitRebase "-i"<cr>
    map <buffer> ,gd :GitDiff<cr><cr>
    map <buffer> gf :GitShow<cr><cr>

    map <buffer> ,su :GitSVNRebase<cr><cr>
    map <buffer> ,sp :GitSVNDcommit<cr><cr>
endfunction

call s:GitGraphInit()

" vim: et ts=8 sts=4 sw=4
