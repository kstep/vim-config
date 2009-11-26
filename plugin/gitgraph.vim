
" Common utility functions {{{
function! s:ShellJoin(alist, glue)
    return join(map(alist, 'shellescape(v:val, 1)'), a:glue)
endfunction

function! s:Line(l)
    return type(a:l) == type("") ? line(a:l) : a:l
endfunction

function! s:Col(c)
    return type(a:c) == type("") ? col(a:c) : a:c
endfunction

function! s:GetSynName(l, c)
    return synIDattr(synID(s:Line(a:l), s:Col(a:c), 1), 'name')
endfunction

" a:1 = depth, default to 0
function! s:GetSynRegionName(l, c, ...)
    return synIDattr(synstack(s:Line(a:l), s:Col(a:c))[a:0 > 0 ? a:1 : 0], 'name')
endfunction

function! s:SynSearch(pattern, synnames)
    while 1
        let found = searchpos(a:pattern)
        if found == [0,0] | break | endif
        let synname = synIDattr(synID(found[0], found[1], 1), 'name')
        if index(a:synnames, synname) > -1 | break | endif
    endwhile
endfunction

function! s:Scratch(bufname, size, cmd, vert)
    let bufpat = "^".escape(a:bufname, "[]*+")."$"
    let bufno = bufnr(bufpat)
    if a:vert
        let vert = 'v'
        let wert = '|'
    else
        let vert = ''
        let wert = '_'
    endif
    if bufno == -1
        exec vert . "new"
        exec a:size."wincmd " . wert
        setl noswf bt=nofile bh=hide
        exec "file " . escape(a:bufname, " ")
    else
        let winno = bufwinnr(bufno)
        if winno == -1
            exec vert . "split +buffer" . bufno
            exec a:size."wincmd " . wert
        elseif winno != winnr()
            exec winno."wincmd w"
        endif
    endif

    if !empty(a:cmd)
        setl ma
        1,$delete
        exec a:cmd
        setl noma nomod
    endif
    goto 1
endfunction
" }}}

" Common git helper functions {{{
function! s:GitGetRepository()
    let reponame = system(s:gitgraph_git_path . ' rev-parse --git-dir')[:-2]
    if reponame ==# '.git'
        let reponame = getcwd()
    else
        let reponame = fnamemodify(reponame, ':h')
    endif
    return reponame
endfunction

function! s:GetLineCommit(line)
    return matchstr(getline(a:line), '\<[a-f0-9]\{7,40}\>')
endfunction

function! s:GetRegCommit(regn)
    return split(getreg(regn), "\n")
endfunction

function! s:GitBranchCompleter(arg, cline, cpos)
    let cmd = s:gitgraph_git_path . ' branch'
    let lst = join(map(split(system(cmd), "\n"), 'v:val[2:]'), "\n")
    return lst
endfunction
" }}}

" Exported functions {{{
function! GitGraphFolder(lnum)
    let regex = '\([0-9][|] \)* [*] '
    let bline = matchstr(getline(a:lnum-1), regex)
    let aline = matchstr(getline(a:lnum+1), regex)
    let line = matchstr(getline(a:lnum), regex)
    return bline ==# line && aline ==# line
endfunction

function! GitGraphGotoFile(fname)
    let repopath = s:GitGetRepository()
    let fname = a:fname
    if fname =~# "^[ab]/" | let fname = fname[2:] | endif
    if repopath != "" | let fname = repopath . "/" . fname | endif
    return fname
endfunction
" }}}

" GitGraph view implementation {{{
function! s:GitGraphMappings()
    command! -buffer -range GitYankRange :call setreg(v:register, <SID>GetLineCommit(<line1>)."\n".<SID>GetLineCommit(<line2>), "l")
    command! -buffer -bang -range GitRebase :call <SID>GitRebase(<SID>GetLineCommit(<line1>), <SID>GetLineCommit(<line2>), '', '<bang>'=='!')
    command! -buffer -bang GitRebaseOnto :let rng = <SID>GetRegCommit(v:register) | call <SID>GitRebase(rng[0], rng[1], <SID>GetLineCommit('.'), '<bang>'=='!')
    command! -buffer -nargs=* -range GitDiff :call <SID>GitDiff(<SID>GetLineCommit(<line1>), <SID>GetLineCommit(<line2>), <f-args>)
    command! -buffer GitShow :call <SID>GitShow(<SID>GetLineCommit('.'))
    command! -buffer GitNextRef :call <SID>GitGraphNextRef()

    command! -buffer -bang GitDelete :call <SID>GitDelete(expand('<cword>'), <SID>GetSynName('.', '.'), '<bang>'=='!')
    command! -buffer -bang GitRevert :call <SID>GitRevert(<SID>GetLineCommit('.'), '<bang>'=='!')
    command! -buffer GitBranch :call <SID>GitBranch(<SID>GetLineCommit('.'), input("Enter new branch name: "))
    command! -buffer GitTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "))
    command! -buffer GitSignedTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "), "s")
    command! -buffer GitAnnTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "), "a")

    command! -buffer -bang GitPush :call <SID>GitPush(expand('<cword>'), <SID>GetSynName('.', '.'), '<bang>'=='!')
    command! -buffer GitPull :call <SID>GitPull(expand('<cword>'), <SID>GetSynName('.', '.'))
    command! -buffer GitCheckout :call <SID>GitCheckout(expand('<cword>'), <SID>GetSynName('.', '.'))

    command! -buffer GitSVNRebase :call <SID>GitSVNRebase(expand('<cword>'), <SID>GetSynName('.', '.'))
    command! -buffer GitSVNDcommit :call <SID>GitSVNDcommit(expand('<cword>'), <SID>GetSynName('.', '.'))

    " (y)ank range into buffer and (p)ut it somewhere (aka rebase onto)
    map <buffer> Y :GitYankRange<cr>
    vmap <buffer> Y :GitYankRange<cr>
    map <buffer> P :GitRebaseOnto<cr>

    " (d)elete (w)ord, commit (aka revert)
    map <buffer> dw :GitDelete<cr>
    map <buffer> dW :GitDelete!<cr>
    map <buffer> dd :GitRevert<cr>
    map <buffer> DD :GitRevert!<cr>

    " (g)o (b)ranch, (p)ush, p(u)ll
    map <buffer> gp :GitPush<cr><cr>
    map <buffer> gu :GitPull<cr><cr>
    map <buffer> gb :GitCheckout<cr><cr>

    " (a)dd (b)ranch, (t)ag, (a)nnotated/(s)igned tag
    map <buffer> ab :GitBranch<cr>
    map <buffer> at :GitTag<cr>
    map <buffer> aa :GitAnnTag<cr>
    map <buffer> as :GitSignedTag<cr>

    " (g)o (r)ebase (interactive), (d)iff, (f)ile (aka commit)
    vmap <buffer> gr :GitRebase<space>
    vmap <buffer> gR :GitRebase!<cr>
    map <buffer> gd :GitDiff<cr><cr>
    map <buffer> gf :GitShow<cr><cr>

    " like gu/gp, but for git-svn
    map <buffer> gU :GitSVNRebase<cr><cr>
    map <buffer> gP :GitSVNDcommit<cr><cr>

    map <buffer> <Tab> :GitNextRef<cr>
endfunction

function! s:GitGraphNew(branch, afile)
    let repopath = s:GitGetRepository()
    let reponame = fnamemodify(repopath, ':t')
    call s:Scratch('[Git Graph:'.reponame.']', 20, '', 0)
    let b:gitgraph_file = a:afile
    let b:gitgraph_branch = a:branch
    let b:gitgraph_repopath = repopath
    exec 'lcd ' . repopath
    au ColorScheme <buffer> setl ft=gitgraph | call s:GitGraphMarkHead()
    call s:GitGraphMappings()
endfunction

function! s:GitGraphMarkHead()
    let commit = system(s:gitgraph_git_path . ' rev-parse --short HEAD')[:-2]
    let branch = system(s:gitgraph_git_path . ' symbolic-ref -q HEAD')[11:-2]
    silent! syn clear gitgraphHeadRefItem
    exec 'syn keyword gitgraphHeadRefItem ' . commit . ' ' . branch . ' contained'
endfunction

function! s:GitGraphNextRef()
    call s:SynSearch('\<\([a-z]\+:\)\?[a-zA-Z0-9./_-]\+\>',
            \ ["gitgraphRefItem", "gitgraphHeadRefItem",
            \ "gitgraphTagItem", "gitgraphRemoteItem",
            \ "gitgraphStashItem"])
endfunction

" a:1 - branch, a:2 - order, a:3 - file
function! s:GitGraph(...)
    let branch = exists('a:1') && a:1 != '' ? a:1 : ''
    let order = exists('a:2') && a:2 ? 'date' : 'topo'
    let afile = exists('a:3') && a:3 != '' ? a:3 : ''

    if exists('b:gitgraph_repopath')
        if afile == '' | let afile = b:gitgraph_file | endif
        if branch == '' | let branch = b:gitgraph_branch | endif
        exec 'lcd ' . b:gitgraph_repopath
    else
        call s:GitGraphNew(branch, afile)
    endif

    let cmd = "0read !" . s:gitgraph_git_path . " log --graph --decorate=full --date=" . g:gitgraph_date_format . " --format=format:" . s:gitgraph_graph_format . " --abbrev-commit --color --" . order . "-order " . branch . " -- " . afile
    setl ma
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
    exec 'setl gp=' . s:gitgraph_git_path . '\ grep\ -n\ $*\ --\ ' . escape(b:gitgraph_repopath, ' ')
    call s:GitGraphMarkHead()
endfunction
" }}}

" GitStatus view implementation {{{
function! s:GitStatusNextFile()
    call s:SynSearch('\[[ +*-]\]', ['gitModFile', 'gitNewFile', 'gitDelFile', 'gitUnFile'])
endfunction

function! s:GitStatusGetFile(l)
    let synname = s:GetSynName(a:l, '.')
    if synname ==# 'gitModFile' || synname ==# 'gitNewFile'
        \ || synname ==# 'gitDelFile' || synname ==# 'gitUnFile'
        return getline(a:l)[5:]
    else
        return ""
    endif
endfunction

function! s:GitStatusRevertFile(fname, region)
    if a:fname == '' | return | endif
    if a:region ==# 'gitStaged'
        call s:GitResetFiles(a:fname)
    elseif a:region ==# 'gitUnstaged'
        call s:GitCheckoutFiles(a:fname, 1)
    elseif a:region ==# 'gitUntracked'
        if confirm('Remove untracked file "'.a:fname.'"?', '&Yes\n&No') == 1
            exec '!rm -f ' . shellescape(fname, 1)
        endif
    else
        return
    endif
    call s:GitStatus()
endfunction

function! s:GitStatusAddFile(fname, region)
    if a:fname == '' | return | endif
    if a:region ==# 'gitUnstaged' || a:region ==# 'gitUntracked'
        call s:GitAddFiles(a:fname)
    else
        return
    endif
    call s:GitStatus()
endfunction

function! s:GitStatusMappings()
    command! -buffer GitNextFile :call <SID>GitStatusNextFile()
    command! -buffer GitRevertFile :call <SID>GitStatusRevertFile(<SID>GitStatusGetFile('.'), <SID>GetSynRegionName('.', '.'))
    command! -buffer GitAddFile :call <SID>GitStatusAddFile(<SID>GitStatusGetFile('.'), <SID>GetSynRegionName('.', '.'))

    map <buffer> <Tab> :GitNextFile<cr>
    map <buffer> dd :GitRevertFile<cr>
    map <buffer> yy :GitAddFile<cr>
endfunction

function! s:GitStatus()
    let cmd = '0read !' . s:gitgraph_git_path .  ' status'
    call s:Scratch('[Git Status]', 30, cmd, 1)
    setl ma
    silent! g!/^#\( Changes\| Changed\| Untracked\|\t\|\s*$\)/delete
    silent! g/^#\( Changes\| Changed\| Untracked\)/.+1delete
    silent! %s/^#\tmodified:   /\t[*] /e
    silent! %s/^#\tnew file:   /\t[+] /e
    silent! %s/^#\tdeleted:    /\t[-] /e
    silent! %s/^#\t/\t[ ] /e
    silent! %s/^#\s*$//e
    setl ts=4 noma nomod ft=gitstatus fdm=syntax nowrap cul

    call s:GitStatusMappings()
endfunction
" }}}

" Initializator {{{
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

    if !exists('g:gitgraph_git_path') || g:gitgraph_git_path == ''
        let g:gitgraph_git_path = 'git'
    endif

    let s:gitgraph_git_path = g:gitgraph_git_path
    let s:gitgraph_graph_format = shellescape('%Creset%h%d ' . g:gitgraph_subject_format . ' [' . g:gitgraph_authorship_format . ']', 1)

    command! -nargs=* -complete=custom,<SID>GitBranchCompleter GitGraph :call <SID>GitGraph(<f-args>)
    command! GitStatus :call <SID>GitStatus()

    map ,gg :GitGraph "--all"<cr><cr>
    map ,gs :GitStatus<cr><cr>
    map ,gf :exec 'GitGraph "--all" 0 '.expand('%:p')<cr><cr>
endfunction
" }}}

" Git commands interface {{{
function! s:GitBranch(commit, branch)
    if a:branch != ""
        exec "!" . s:gitgraph_git_path . " branch " . shellescape(a:branch, 1) . " " . a:commit
        call s:GitGraph()
    endif
endfunction

" a:1 - mode (none/'a'/'s'), a:1 - key id
function! s:GitTag(commit, tag, ...)
    if a:tag != ""
        let mode = ''
        if exists('a:1')
            if a:1 ==# 'a'
                let mode = '-a'
            elseif a:1 ==# 's'
                let mode = exists('a:2') && a:2 ? '-u '.a:2 : '-s'
            endif
        endif
        exec "!" . s:gitgraph_git_path . " tag " . mode . " " . shellescape(a:tag, 1) . " " . a:commit
        call s:GitGraph()
    endif
endfunction

" a:1 - nocommit, a:2 - noff, a:3 - squash
function! s:GitMerge(tobranch, frombranch, ...)
    if a:tobranch != '' && a:frombranch != ''
        let nocommit = exists('a:1') && a:1 '--no-commit' : '--commit'
        let nofastfwd = exists('a:2') && a:2 '--no-ff' : '--ff'
        let squash = exists('a:3') && a:3 '--squash' : '--no-squash'
        exec '!' . s:gitgraph_git_path . ' checkout ' . shellescape(a:tobranch, 1) . ' && ' . s:gitgraph_git_path . ' merge ' . nocommit . ' ' . nofastfwd . ' ' . squash . ' ' . shellescape(a:frombranch, 1)
        call s:GitGraph()
    endif
endfunction

" a:1 = interactive
function! s:GitRebase(branch, upstream, onto, ...)
    if a:branch != "" && a:upstream != ""
        let onto = a:onto == "" ? a:upstream : a:onto
        let iact = exists('a:1') && a:1 ? '--interactive' : ''
        exec "!" . s:gitgraph_git_path . " rebase " . iact . " --onto " . onto . " " . a:upstream . " " . a:branch
        call s:GitGraph()
    endif
endfunction

" a:1 = cached, a:2 = files
function! s:GitDiff(fcomm, tcomm, ...)
    if a:fcomm != "" && a:tcomm != ""
        let cached = exists('a:1') && a:1 ? '--cached' : ''
        let paths = exists('a:2') && a:2 ? s:ShellJoin(a:2, ' ') : ''
        let cmd = "0read !" . s:gitgraph_git_path . " diff " . cached . " " . a:tcomm
        if a:fcomm != a:tcomm | let cmd = cmd . " " . a:fcomm | endif
        let cmd = cmd . ' -- ' . paths
        call s:Scratch("[Git Diff]", 15, cmd, 0)
        setl ft=diff inex=GitGraphGotoFile(v:fname)
        map <buffer> <C-f> /^diff --git<CR>
        map <buffer> <C-b> ?^diff --git<CR>
    endif
endfunction

function! s:GitShow(commit, ...)
    if a:commit != ""
        let cmd = "0read !" . s:gitgraph_git_path . " show " . join(a:000, " ") . " " . a:commit
        call s:Scratch("[Git Show]", 15, cmd, 0)
        setl ft=diff.gitlog inex=GitGraphGotoFile(v:fname)
        map <buffer> <C-f> /^diff --git<CR>
        map <buffer> <C-b> ?^diff --git<CR>
    endif
endfunction

" a:1 - force
function! s:GitPush(word, syng, ...)
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(a:word[7:], "/")
        let force = exists("a:1") && a:1 ? "-f" : ""
        exec "!" . s:gitgraph_git_path . " push " . force . " " . parts[0] . " " . join(parts[1:], "/")
        call s:GitGraph()
    endif
endfunction

function! s:GitCheckout(word, syng)
    if a:syng == 'gitgraphRefItem'
        exec "!" . s:gitgraph_git_path . " checkout " . a:word
        call s:GitGraphMarkHead()
    endif
endfunction

function! s:GitPull(word, syng)
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(a:word[7:], "/")
        exec "!" . s:gitgraph_git_path . " pull " . parts[0] . " " . join(parts[1:], "/")
        call s:GitGraph()
    endif
endfunction

" a:1 - force
function! s:GitDelete(word, syng, ...)
    let force = exists("a:1") && a:1
    if a:syng == 'gitgraphRefItem'
        let par = force ? "-D" : "-d"
        let cmd = "!" . s:gitgraph_git_path . " branch " . par . " " . a:word
    elseif a:syng == 'gitgraphTagItem'
        let cmd = "!" . s:gitgraph_git_path . " tag -d " . a:word[4:]
    elseif a:syng == 'gitgraphRemoteItem'
        let par = force ? "-f" : ""
        let parts = split(a:word[7:], "/")
        let cmd = "!" . s:gitgraph_git_path . " push " . par . " " . parts[0] . " " . join(parts[1:], "/") . ":"
    else
        return
    endif
    exec cmd
    "echo cmd
    call s:GitGraph()
endfunction

function! s:GitSVNRebase(word, syng)
    call s:GitCheckout(a:word, a:syng)
    exec "!" . s:gitgraph_git_path . " svn rebase"
    call s:GitGraph()
endfunction

function! s:GitSVNDcommit(word, syng)
    call s:GitCheckout(a:word, a:syng)
    exec "!" . s:gitgraph_git_path . " svn dcommit"
    call s:GitGraph()
endfunction

" a:1 = force, a:2 = patch
function! s:GitAddFiles(fname, ...)
    let files = type(a:fname) == type([]) ? s:ShellJoin(a:fname, " ") : shellescape(a:fname, 1)
    let force = exists('a:1') && a:1 ? '--force' : ''
    let patch = exists('a:2') && a:2 ? '--patch' : ''
    exec '!' . s:gitgraph_git_path . ' add ' . force . ' ' . patch . ' -- ' . files
endfunction

" a:1 = patch
function! s:GitResetFiles(fname, ...)
    let patch = exists('a:1') && a:1 ? '--patch' : ''
    let files = type(a:fname) == type([]) ? s:ShellJoin(a:fname, " ") : shellescape(a:fname, 1)
    exec '!' . s:gitgraph_git_path . ' reset ' . patch . ' -- ' . files
endfunction

" a:1 = force
function! s:GitCheckoutFiles(fname, ...)
    let force = exists("a:1") && a:1 ? "-f" : ""
    let files = type(a:fname) == type([]) ? s:ShellJoin(a:fname, " ") : shellescape(a:fname, 1)
    exec "!" . s:gitgraph_git_path . " checkout " . force . " -- " . files
endfunction

" a:1 = nocommit, a:2 = edit, a:3 = signoff
function! s:GitRevert(commit, ...)
    let nocommit = exists('a:1') && a:1 ? '--no-commit' : ''
    let edit = exists('a:2') && a:2 ? '--edit' : '--no-edit'
    let signoff = exists('a:3') && a:3 ? '--signoff' : ''
    exec '!' . s:gitgraph_git_path . ' revert ' . nocommit . ' ' . edit . ' ' . signoff . ' ' . shellescape(commit, 1)
endfunction

" a:1 = nocommit, a:2 = edit, a:3 = signoff, a:4 = attribute
function! s:GitCherryPick(commit, ...)
    let nocommit = exists('a:1') && a:1 ? '--no-commit' : ''
    let edit = exists('a:2') && a:2 ? '--edit' : ''
    let signoff = exists('a:3') && a:3 ? '--signoff' : ''
    let attrib = exists('a:4') && a:4 ? '-x' : '-r'
    exec '!' . s:gitgraph_git_path . ' cherry-pick ' . nocommit . ' ' . edit . ' ' . signoff . ' ' . attrib . ' ' . shellescape(commit, 1)
endfunction
" }}}

call s:GitGraphInit()

" vim: et ts=8 sts=4 sw=4
