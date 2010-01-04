
" Common utility functions {{{
function! s:ShellJoin(alist, glue)
    return type(a:alist) == type([]) ? join(map(a:alist, 'shellescape(v:val, 1)'), a:glue) : shellescape(a:alist, 1)
endfunction

function! s:Line(l)
    return type(a:l) == type('') ? line(a:l) : a:l
endfunction

function! s:Col(c)
    return type(a:c) == type('') ? col(a:c) : a:c
endfunction

function! s:GetSynName(l, c)
    return synIDattr(synID(s:Line(a:l), s:Col(a:c), 1), 'name')
endfunction

" a:1 = depth, default to 0
function! s:GetSynRegionName(l, c, ...)
    return synIDattr(synstack(s:Line(a:l), s:Col(a:c))[a:0 > 0 ? a:1 : 0], 'name')
endfunction

function! s:SynSearch(pattern, synnames, back)
    while 1
        let found = searchpos(a:pattern, a:back ? 'bW' : 'W')
        if found == [0,0] | break | endif
        let synname = synIDattr(synID(found[0], found[1], 1), 'name')
        if index(a:synnames, synname) > -1 | break | endif
    endwhile
endfunction

function! s:ExtractLayout(obj)
    return get(g:gitgraph_layout, a:obj, [30,'rb'])
endfunction

" bufname = buffer name to open
" sizes = if int its a width (height if below 0), if < 0 split vertically,
" if string its a layout element to use.
" a:1 = cmd = command to run to fill the new window,
" a:2 = gravity = one of commands la(leftabove)/rb(rightbelow)/tl(topleft)/br(botright)/t(tab).
let s:gitgraph_gravities = { 't': 'tab', 'la': 'leftabove', 'rb': 'rightbelow', 'tl': 'topleft', 'br': 'botright' }
function! s:Scratch(bufname, size, ...)

    " parse args at first
    if type(a:size) == type('')
        let [size, gravity] = s:ExtractLayout(a:size)
    else
        let size = a:size
        let gravity = exists('a:2') ? a:2 : 'rb'
    endif

    let gravity = get(s:gitgraph_gravities, gravity, 'rb')
    let vertical = '_'

    " negative size opens vertical window
    if size < 0
        let vertical = '|'
        let gravity = 'vertical ' . gravity
        let size = -size
    end

    " now we must try to find buffer with the name
    let bufpat = '^\V'.a:bufname.'\$'
    let bufno = bufnr(bufpat)

    " no buffer is created yet
    if bufno == -1
        exec gravity . ' new'
        if size > 1 | exec size.'wincmd ' . vertical | endif
        setl noswf nonu nospell bt=nofile bh=hide
        exec 'file ' . escape(a:bufname, ' ')

    " yup, we have a buffer, switch to it
    else
        let winno = bufwinnr(bufno)

        " the buffer is not opened in any window, open it up
        if winno == -1
            exec gravity . ' split +buffer' . bufno
            if size > 1 | exec size.'wincmd ' . vertical | endif

        " the buffer is opened in some window, so switch to it if necessary
        elseif winno != winnr()
            exec winno."wincmd w"
        endif
    endif

    " if we are provided with filling command, run it now
    if exists('a:1') && !empty(a:1)
        setl ma
        1,$delete
        exec a:1
    endif

    " the buffer is not modifiable
    setl noma nomod
    goto 1
    return bufnr('.')
endfunction
" }}}

" Common git helper functions {{{
function! s:GitGetRepository()
    let reponame = s:GitSys('rev-parse --git-dir')[:-2]
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
    let lst = join(map(split(s:GitSys('branch'), "\n"), 'v:val[2:]'), "\n")
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
    if fname =~# '^[ab]/' | let fname = fname[2:] | endif
    if !empty(repopath) | let fname = repopath . '/' . fname | endif
    return fname
endfunction
" }}}

" GitGraph view implementation {{{
function! s:GitGraphMappings()
    command! -buffer -range GitYankRange :call setreg(v:register, <SID>GetLineCommit(<line1>)."\n".<SID>GetLineCommit(<line2>), "l")
    command! -buffer -bang -range GitRebase :call <SID>GitRebase(<SID>GetLineCommit(<line1>), <SID>GetLineCommit(<line2>), '', <q-bang>=='!')
    command! -buffer -bang GitRebaseOnto :let rng = <SID>GetRegCommit(v:register) | call <SID>GitRebase(rng[0], rng[1], <SID>GetLineCommit('.'), <q-bang>=='!')
    command! -buffer -bang GitRebaseCurrent :call <SID>GitRebase('', <SID>GetLineCommit('.'), '', <q-bang>=='!')
    command! -buffer -bang -nargs=* -range GitDiff :call <SID>GitDiff(<SID>GetLineCommit(<line1>), <SID>GetLineCommit(<line2>), <q-bang>=='!', <f-args>)
    command! -buffer GitShow :call <SID>GitShow(<SID>GetLineCommit('.'))
    command! -buffer -bang GitNextRef :call <SID>GitGraphNextRef(<q-bang>=='!')

    command! -buffer -bang GitDelete :call <SID>GitDelete(expand('<cword>'), <SID>GetSynName('.', '.'), <q-bang>=='!')
    command! -buffer -bang GitRevert :call <SID>GitRevert(<SID>GetLineCommit('.'), <q-bang>=='!')
    command! -buffer GitBranch :call <SID>GitBranch(<SID>GetLineCommit('.'), input("Enter new branch name: "))
    command! -buffer GitTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "))
    command! -buffer GitSignedTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "), "s")
    command! -buffer GitAnnTag :call <SID>GitTag(<SID>GetLineCommit('.'), input("Enter new tag name: "), "a")

    command! -buffer -bang GitPush :call <SID>GitPush(expand('<cword>'), <SID>GetSynName('.', '.'), <q-bang>=='!')
    command! -buffer GitPull :call <SID>GitPull(expand('<cword>'), <SID>GetSynName('.', '.'))
    command! -buffer GitCheckout :call <SID>GitCheckout(expand('<cword>'), <SID>GetSynName('.', '.'))

    command! -buffer GitSVNRebase :call <SID>GitSVNRebase(expand('<cword>'), <SID>GetSynName('.', '.'))
    command! -buffer GitSVNDcommit :call <SID>GitSVNDcommit(expand('<cword>'), <SID>GetSynName('.', '.'))

    command! -buffer -bang -count GitCommit :call <SID>GitCommitView(<SID>GetLineCommit('.'),<q-bang>=='!','c',<count>)

    " (y)ank range into buffer and (r)ebase onto another branch
    map <buffer> Y :GitYankRange<cr>
    vmap <buffer> Y :GitYankRange<cr>
    map <buffer> R :GitRebaseOnto<cr>
    map <buffer> r :GitRebaseCurrent<cr>

    " (d)elete (w)ord, commit (aka revert)
    map <buffer> dw :GitDelete<cr>
    map <buffer> dW :GitDelete!<cr>
    map <buffer> dd :GitRevert<cr>
    map <buffer> DD :GitRevert!<cr>

    " (g)o (b)ranch, (p)ush, p(u)ll
    map <buffer> gp :GitPush<cr>
    map <buffer> gu :GitPull<cr>
    map <buffer> gb :GitCheckout<cr>

    " (a)dd (b)ranch, (t)ag, (a)nnotated/(s)igned tag, (c)ommit, a(m)end
    map <buffer> ab :GitBranch<cr>
    map <buffer> at :GitTag<cr>
    map <buffer> aa :GitAnnTag<cr>
    map <buffer> as :GitSignedTag<cr>
    map <buffer> ac :GitCommit<cr>
    map <buffer> am :GitCommit!<cr>

    " (g)o (r)ebase (interactive), (d)iff, (f)ile (aka commit)
    vmap <buffer> gr :GitRebase<space>
    vmap <buffer> gR :GitRebase!<cr>
    map <buffer> gd :GitDiff<cr>
    map <buffer> gf :GitShow<cr>

    " like gu/gp, but for git-svn
    map <buffer> gU :GitSVNRebase<cr>
    map <buffer> gP :GitSVNDcommit<cr>

    map <buffer> <Tab> :GitNextRef<cr>
    map <buffer> <S-Tab> :GitNextRef!<cr>
endfunction

function! s:GitGraphNew(branch, afile)
    let repopath = s:GitGetRepository()
    let reponame = fnamemodify(repopath, ':t')
    call s:Scratch('[Git Graph:'.reponame.']', 'g')
    let b:gitgraph_file = a:afile
    let b:gitgraph_branch = a:branch
    let b:gitgraph_repopath = repopath
    exec 'lcd ' . repopath
    au ColorScheme <buffer> setl ft=gitgraph | call s:GitGraphMarkHead()
    call s:GitGraphMappings()
endfunction

function! s:GitGraphMarkHead()
    let commit = s:GitSys('rev-parse --short HEAD')[:-2]
    let branch = s:GitSys('symbolic-ref -q HEAD')[11:-2]
    silent! syn clear gitgraphHeadRefItem
    exec 'syn keyword gitgraphHeadRefItem ' . commit . ' ' . branch . ' contained'
endfunction

function! s:GitGraphNextRef(back)
    call s:SynSearch('\<\([a-z]\+:\)\?[a-zA-Z0-9./_-]\+\>',
            \ ["gitgraphRefItem", "gitgraphHeadRefItem",
            \ "gitgraphTagItem", "gitgraphRemoteItem",
            \ "gitgraphStashItem"], a:back)
endfunction

" a:1 - branch, a:2 - order, a:3 - file
function! s:GitGraphView(...)
    let branch = exists('a:1') && !empty(a:1) ? a:1 : ''
    let order = exists('a:2') && a:2 ? 'date' : 'topo'
    let afile = exists('a:3') && !empty(a:3) ? a:3 : ''

    if exists('b:gitgraph_repopath')
        if empty(afile) | let afile = b:gitgraph_file | endif
        if empty(branch) | let branch = b:gitgraph_branch | endif
        exec 'lcd ' . b:gitgraph_repopath
    else
        call s:GitGraphNew(branch, afile)
    endif

    let cmd = s:GitRead('log', '--graph', '--decorate=full', '--date='.g:gitgraph_date_format, '--format=format:'.s:gitgraph_graph_format, '--abbrev-commit', '--color', '--'.order.'-order', branch, '--', afile)
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
function! s:GitStatusNextFile(back)
    call s:SynSearch('\[[ =+*-]\]', ['gitModFile', 'gitNewFile', 'gitDelFile', 'gitUnFile'], a:back)
endfunction

function! s:GitStatusGetFile(lineno)
    let synname = s:GetSynName(a:lineno, 5)
    if synname ==# 'gitModFile' || synname ==# 'gitNewFile'
        \ || synname ==# 'gitDelFile' || synname ==# 'gitUnFile'
        \ || synname ==# 'gitRenFile'
        return getline(a:lineno)[5:]
    endif
    return ''
endfunction

function! s:GitStatusGetFilesDict(l1, l2)
    let filelist = { 'gitModFile': [], 'gitNewFile': [], 'gitDelFile': [], 'gitUnFile': [], 'gitRenFile': [] }
    for lineno in range(a:l1, a:l2)
        let fname = s:GitStatusGetFile(lineno)
        let synname = s:GetSynName(lineno, 5)
        if !empty(fname)
            call add(filelist[synname], fname)
        endif
    endfor
    return filelist
endfunction

function! s:GitStatusGetFiles(l1, l2)
    let filelist = []
    for lineno in range(a:l1, a:l2)
        let fname = s:GitStatusGetFile(lineno)
        if !empty(fname)
            call add(filelist, fname)
        endif
    endfor
    return filelist
endfunction

function! s:GitStatusRevertFile(fname, region)
    if empty(a:fname) | return | endif
    if a:region ==# 'gitStaged'
        call s:GitResetFiles(a:fname)
    elseif a:region ==# 'gitUnstaged'
        call s:GitCheckoutFiles(a:fname, 1)
    elseif a:region ==# 'gitUntracked'
        call s:GitRemoveFiles(a:fname)
    else
        return
    endif
    call s:GitStatusView()
endfunction

function! s:GitStatusAddFile(fname, region)
    if empty(a:fname) | return | endif
    if a:region ==# 'gitUnstaged' || a:region ==# 'gitUntracked'
        if type(a:fname) == type({})
            call s:GitAddFiles(a:fname['gitUnFile'])
            call s:GitAddFiles(a:fname['gitModFile'])
            call s:GitAddFiles(a:fname['gitRenFile'])
            call s:GitPurgeFiles(a:fname['gitDelFile'])
        else
            call s:GitAddFiles(a:fname)
        endif
    else
        return
    endif
    call s:GitStatusView()
endfunction

function! s:GitStatusMappings()
    command! -buffer -bang GitNextFile :call <SID>GitStatusNextFile(<q-bang>==1)
    command! -buffer -range GitRevertFile :call <SID>GitStatusRevertFile(<SID>GitStatusGetFiles(<line1>, <line2>), <SID>GetSynRegionName(<line1>, '.'))
    command! -buffer -range GitAddFile :call <SID>GitStatusAddFile(<SID>GitStatusGetFilesDict(<line1>, <line2>), <SID>GetSynRegionName(<line1>, '.'))
    command! -buffer -range GitDiff :call <SID>GitDiff('HEAD', 'HEAD', <SID>GetSynRegionName('.', '.') ==# 'gitStaged', <SID>GitStatusGetFiles(<line1>, <line2>))

    map <buffer> <Tab> :GitNextFile<cr>
    map <buffer> <S-Tab> :GitNextFile!<cr>
    map <buffer> dd :GitRevertFile<cr>
    map <buffer> yy :GitAddFile<cr>
    map <buffer> gd :GitDiff<cr>
    map <buffer> gf <C-w>gf
endfunction

function! s:GitStatusView()
    let repopath = s:GitGetRepository()
    let cmd = 'lcd ' . repopath . ' | ' . s:GitRead('status')
    call s:Scratch('[Git Status]', 's', cmd)
    setl ma
    silent! g!/^#\( Changes\| Changed\| Untracked\|\t\|\s*$\)/delete
    silent! g/^#\( Changes\| Changed\| Untracked\)/.+1delete
    silent! %s/^#\tmodified:   /\t[*] /e
    silent! %s/^#\tnew file:   /\t[+] /e
    silent! %s/^#\tdeleted:    /\t[-] /e
    silent! %s/^#\trenamed:    /\t[=] /e
    silent! %s/^#\t/\t[ ] /e
    silent! %s/^#\s*$//e
    if has('perl') || has('perl/dyn')
        silent! g/^\t\[.\] \".*\"$/perldo s/\\([0-7]{1,3})|(")/if($2){""}else{$c=oct($1);if(($c&0xc0)==0x80){$a=($a<<6)|($c&63);$i--}else{for($m=0x80,$i=-1;($m&$c)!=0;$m>>=1){$i++};$a=$c&($m-1)};$i>0?"":chr($a)}/ge
    end
    setl ts=4 noma nomod ft=gitstatus fdm=syntax nowrap cul

    call s:GitStatusMappings()
endfunction
" }}}

" GitCommit view implementation {{{
function! s:GitCommitView(msg, amend, src, signoff)
    call s:Scratch('[Git Commit]', 'c', '1') | set ma

    if a:src == 'c'
        let message = substitute(s:GitSys('cat-file', 'commit', a:msg), '^.\{-}\n\n', '', '')
    elseif a:src == 'f'
        let message = readfile(a:msg)
    elseif a:amend && empty(a:msg)
        let message = substitute(s:GitSys('cat-file', 'commit', 'HEAD'), '^.\{-}\n\n', '', '')
    else
        let message = a:msg
    endif

    silent 0put =message
    silent put ='## -------------------------------------------------------------------------------------'
    silent put ='## Enter commit message here. Write it (:w) to commit or close the buffer (:q) to cancel.'
    silent put ='## Lines starting with ## are removed from commit message.'

    let submessage = ''
    if a:amend | let submessage = submessage . '¹This is an amend commit. ' | endif
    if a:signoff | let submessage = submessage . '²This commit will be signed off with your signature. ' | endif
    if !empty(submessage)
        silent put ='## '.submessage
    endif

    1

    setl ft=gitcommit bt=acwrite bh=wipe nomod
    let b:gitgraph_commit_amend = a:amend
    let b:gitgraph_commit_signoff = a:signoff
    augroup GitCommitView
        au!
        au BufWriteCmd <buffer> call s:GitCommitBuffer()
    augroup end
endfunction

function! s:GitCommitBuffer()
    let bufno = bufnr('%')
    let message = filter(getbufline('%', 1, '$'), 'strpart(v:val, 0, 2) != "##"')
    let msgfile = tempname()
    call writefile(message, msgfile)
    try
        call s:GitCommit(msgfile, b:gitgraph_commit_amend, 0, b:gitgraph_commit_signoff, 'f') | set nomod
        if bufno >= 0 | exec 'bwipeout! '.bufno | endif
    finally
        call delete(msgfile)
    endtry
    call s:GitStatusView()
endfunction
" }}}

" Initializator {{{
function! s:GitGraphInit()

    " commits subject format to show in graph, defaults to simple commit subject
    if !exists('g:gitgraph_subject_format') || empty(g:gitgraph_subject_format)
        let g:gitgraph_subject_format = '%s'
    end

    " authorship mark, placed after commit subject in tree, defaults to author
    " name & timestamp
    if !exists('g:gitgraph_authorship_format') || empty(g:gitgraph_authorship_format)
        let g:gitgraph_authorship_format = '%aN, %ad'
    end

    " date format to show in authorship mark in graph, defaults to "short"
    " format, like "3 days ago"
    if !exists('g:gitgraph_date_format') || empty(g:gitgraph_date_format)
        let g:gitgraph_date_format = 'short'
    end

    " git path, if not set git sohuld be in your PATH
    if !exists('g:gitgraph_git_path') || empty(g:gitgraph_git_path)
        let g:gitgraph_git_path = 'git'
    endif

    " gitgraph layout configuration, defines how to place different views namely:
    " g = (g)raph view,
    " s = (s)tatus view,
    " t = s(t)ash view (todo),
    " d = (d)iff view,
    " c = (c)ommit view (todo),
    " f = new (f)ile opened from any view (currently diff or status),
    " l = (l)ayout: open these objects in order when activating plugin.
    " format: [gstdcf]:<size>:<gravity>,...,l:[gstdcf]+
    " for size & gravity discription see s:Scratch().
    if !exists('g:gitgraph_layout') || empty(g:gitgraph_layout)
        let g:gitgraph_layout = { 'g':[20,'la'], 's':[-30,'tl'], 'd':[999,'t'], 'f':[20,'rb'], 'l':['g','s'] }
    endif

    let s:gitgraph_git_path = g:gitgraph_git_path
    let s:gitgraph_graph_format = shellescape('%Creset%h%d ' . g:gitgraph_subject_format . ' [' . g:gitgraph_authorship_format . ']', 1)

    command! -nargs=* -complete=custom,<SID>GitBranchCompleter GitGraph :call <SID>GitGraphView(<f-args>)
    command! GitStatus :call <SID>GitStatusView()
    command! -bang -count -nargs=? GitCommit :call <SID>GitCommitView(<q-args>,<q-bang>=='!','',<count>)
    command! -bang -count=3 GitDiff :call <SID>GitDiff('HEAD','HEAD',<q-bang>=='!',expand('%:p'),<q-count>)

    command! GitLayout :call <SID>GitLayout()

    map ,gg :GitGraph "--all"<cr>
    map ,gs :GitStatus<cr>
    map ,gc :GitCommit<cr>
    map ,gd :GitDiff<cr>
    map ,gf :exec 'GitGraph "--all" 0 '.expand('%:p')<cr>

    map ,go :GitLayout<cr>
endfunction
" }}}

" Layout {{{
function! s:GitLayout()
    let layout = get(g:gitgraph_layout, 'l', ['g','s'])
    for obj in layout
        if obj == 'g'
            call s:GitGraphView()
        elseif obj == 's'
            call s:GitStatusView()
        endif
    endfor
endfunction
" }}}

" Git commands interface {{{
function! s:GitCmd(args)
    return s:gitgraph_git_path . ' ' . join(a:args, ' ')
endfunction

function! s:GitRun(...)
    exec 'silent !' . s:GitCmd(a:000)
endfunction
function! s:GitRead(...)
    return 'silent 0read !' . s:GitCmd(a:000)
endfunction
function! s:GitSys(...)
    return system(s:GitCmd(a:000))
endfunction

function! s:GitBranch(commit, branch)
    if !empty(a:branch)
        call s:GitRun('branch', shellescape(a:branch, 1), a:commit)
        call s:GitGraphView()
    endif
endfunction

" a:1 - mode (none/'a'/'s'), a:1 - key id
function! s:GitTag(commit, tag, ...)
    if !empty(a:tag)
        let mode = ''
        if exists('a:1')
            if a:1 ==# 'a'
                let mode = '-a'
            elseif a:1 ==# 's'
                let mode = exists('a:2') && !empty(a:2) ? '-u '.a:2 : '-s'
            endif
        endif
        call s:GitRun('tag', mode, shellescape(a:tag, 1), a:commit)
        call s:GitGraphView()
    endif
endfunction

" a:1 - nocommit, a:2 - noff, a:3 - squash
function! s:GitMerge(tobranch, frombranch, ...)
    if !empty(a:tobranch) && !empty(a:frombranch)
        let nocommit = exists('a:1') && a:1 '--no-commit' : '--commit'
        let nofastfwd = exists('a:2') && a:2 '--no-ff' : '--ff'
        let squash = exists('a:3') && a:3 '--squash' : '--no-squash'
        call s:GitRun('checkout', shellescape(a:tobranch, 1))
        call s:GitRun('merge', nocommit, nofastfwd, squash, shellescape(a:frombranch, 1))
        call s:GitGraphView()
    endif
endfunction

" a:1 = interactive
function! s:GitRebase(branch, upstream, onto, ...)
    if !empty(a:upstream)
        let onto = empty(a:onto) ? a:upstream : a:onto
        let iact = exists('a:1') && a:1 ? '--interactive' : ''
        call s:GitRun('rebase', iact, '--onto', onto, a:upstream, a:branch)
        call s:GitGraphView()
    endif
endfunction

" a:1 = cached, a:2 = files, a:3 = context lines
function! s:GitDiff(fcomm, tcomm, ...)
    if !empty(a:fcomm) && !empty(a:tcomm)
        let cached = exists('a:1') && a:1 ? '--cached' : ''
        let paths = exists('a:2') && !empty(a:2) ? s:ShellJoin(a:2, ' ') : ''
        let ctxl = exists('a:3') ? '-U'.a:3 : ''
        let cmd = s:GitRead('diff', cached, ctxl, a:tcomm, a:fcomm != a:tcomm ? a:fcomm : '', '--', paths)
        call s:Scratch('[Git Diff]', 'd', cmd)
        setl ft=diff inex=GitGraphGotoFile(v:fname) bt=acwrite bh=wipe
        map <buffer> <C-f> /^diff --git<CR>
        map <buffer> <C-b> ?^diff --git<CR>
        map <buffer> dd :call <SID>GitDiffDelete()<CR>
        map <buffer> gf :call <SID>GitDiffGotoFile()<CR>
        augroup GitDiffView
            au!
            au BufWriteCmd <buffer> call s:GitDiffApply()
        augroup end
    endif
endfunction

function! s:GitDiffApply()
    let hunks = getbufline('%', 1, '$')
    let patchfile = tempname()
    try
        call writefile(hunks, patchfile)
        call s:GitApply(patchfile, 1)
        setl nomod
    finally
        call delete(patchfile)
    endtry
endfunction

function! s:GitDiffGotoFile()
    " get header position
    let hdrpos = search('^+++ ', 'nbW')
    if hdrpos < 1 | return "0" | endif
    let chdrpos = search('^@@ ', 'nbW')
    if chdrpos < 1 | return "1" | endif

    " now get chunk position in original file
    let chunkpos = matchstr(getline(chdrpos), '[0-9]\+', 3)
    if empty(chunkpos) | return chdrpos | endif

    " now get diff lines present in current file from header to current pos
    let offlines = filter(getbufline('%', chdrpos+1, line('.')), 'v:val =~ "^[ +]"')

    " and original file name from header
    let origfile = strpart(getline(hdrpos), 5)
    let repopath = s:GitGetRepository()

    " now we have: original file name, first line of chunk in it and
    " lines from chunk's start to our destination pos, so junk
    " open the file and goto to position we seek!
    exec 'edit! '. repopath . origfile
    exec len(offlines)+chunkpos
endfunction

function! s:GitDiffDelete()
    let line = getline('.')
    let hunk = strpart(line, 0, 2)
    if hunk == '@@' " remove whole hunk
        set ma | .,/^@@/-1delete | set noma
    elseif hunk == '++' || hunk == '--' " remove whole file
        set ma | ?^---?,/^---/-1delete | set noma
    elseif strpart(hunk, 0, 1) == '+' " remove added line
        set ma | delete | set noma
    elseif strpart(hunk, 0, 1) == '-' " remove removed line (make it context)
        set ma | call setline('.', ' '.strpart(line, 1)) | set noma
    endif
endfunction

function! s:GitShow(commit, ...)
    if !empty(a:commit)
        let cmd = s:GitRead('show', join(a:000, ' '), a:commit)
        call s:Scratch('[Git Show]', 'f', cmd)
        setl ft=diff.gitlog inex=GitGraphGotoFile(v:fname)
        map <buffer> <C-f> /^diff --git<CR>
        map <buffer> <C-b> ?^diff --git<CR>
        map <buffer> gf :call <SID>GitDiffGotoFile()<CR>
    endif
endfunction

" a:1 - force
function! s:GitPush(word, syng, ...)
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(a:word[7:], '/')
        let force = exists('a:1') && a:1 ? '-f' : ''
        call s:GitRun('push', force, parts[0], join(parts[1:], '/'))
        call s:GitGraphView()
    endif
endfunction

function! s:GitCheckout(word, syng)
    if a:syng == 'gitgraphRefItem'
        call s:GitRun('checkout', a:word)
        call s:GitGraphMarkHead()
    endif
endfunction

function! s:GitPull(word, syng)
    if a:syng == 'gitgraphRemoteItem'
        let parts = split(a:word[7:], '/')
        call s:GitRun('pull', parts[0], join(parts[1:], '/'))
        call s:GitGraphView()
    endif
endfunction

" a:1 - force
function! s:GitDelete(word, syng, ...)
    let force = exists('a:1') && a:1
    if a:syng == 'gitgraphRefItem'
        let par = force ? '-D' : '-d'
        let cmd = 'branch ' . par . ' ' . a:word
    elseif a:syng == 'gitgraphTagItem'
        let cmd = 'tag -d ' . a:word[4:]
    elseif a:syng == 'gitgraphRemoteItem'
        let par = force ? '-f' : ''
        let parts = split(a:word[7:], "/")
        let cmd = 'push ' . par . ' ' . parts[0] . ' ' . join(parts[1:], '/') . ':'
    else
        return
    endif
    call s:GitRun(cmd)
    call s:GitGraphView()
endfunction

function! s:GitSVNRebase(word, syng)
    call s:GitCheckout(a:word, a:syng)
    call s:GitRun('svn rebase')
    call s:GitGraphView()
endfunction

function! s:GitSVNDcommit(word, syng)
    call s:GitCheckout(a:word, a:syng)
    call s:GitRun('svn dcommit')
    call s:GitGraphView()
endfunction

" a:1 = force
function! s:GitAddFiles(fname, ...)
    if empty(a:fname) | return | endif
    let files = s:ShellJoin(a:fname, ' ')
    let force = exists('a:1') && a:1 ? '--force' : ''
    call s:GitRun('add', force, '--', files)
endfunction

" a:1 = force, a:2 = index
function! s:GitPurgeFiles(fname, ...)
    if empty(a:fname) | return | endif
    let files = s:ShellJoin(a:fname, ' ')
    let force = exists('a:1') && a:1 ? '--force' : ''
    let index = exists('a:2') && a:2 ? '--cached' : ''
    call s:GitRun('rm -r', force, index, '--', files)
endfunction

function! s:GitResetFiles(fname)
    if empty(a:fname) | return | endif
    let files = s:ShellJoin(a:fname, ' ')
    call s:GitRun('reset', '--', files)
endfunction

" a:1 = mode: mixed/(s)oft/(h)ard/(m)erge
function! s:GitReset(commit, ...)
    let mode = exists('a:1') ? (a:1 == 's' ? '--soft' : (a:1 == 'h' ? '--hard' : (a:1 == 'm' ? '--merge' : '--mixed'))) : '--mixed'
    call s:GitRun('reset', mode, commit)
endfunction

function! s:GitRemoveFiles(fname)
    if empty(a:fname) | return | endif
    if type(a:fname) == type([])
        if confirm('Remove untracked file'.(len(a:fname) > 1 ? 's' : ' "'.a:fname[0].'"').'?', "&Yes\n&No") == 1
            call map(a:fname, 'delete(v:val)')
        endif
    else
        if confirm('Remove untracked file "'.a:fname.'"?', "&Yes\n&No") == 1
            call delete(a:fname)
        endif
    endif
endfunction

" a:1 = force
function! s:GitCheckoutFiles(fname, ...)
    if empty(a:fname) | return | endif
    let force = exists('a:1') && a:1 ? '-f' : ''
    let files = s:ShellJoin(a:fname, ' ')
    call s:GitRun('checkout', force, '--', files)
endfunction

" a:1 = nocommit, a:2 = edit, a:3 = signoff
function! s:GitRevert(commit, ...)
    let nocommit = exists('a:1') && a:1 ? '--no-commit' : ''
    let edit = exists('a:2') && a:2 ? '--edit' : '--no-edit'
    let signoff = exists('a:3') && a:3 ? '--signoff' : ''
    call s:GitRun('revert', nocommit, edit, signoff, shellescape(commit, 1))
    call s:GitGraphView()
endfunction

" a:1 = nocommit, a:2 = edit, a:3 = signoff, a:4 = attribute
function! s:GitCherryPick(commit, ...)
    let nocommit = exists('a:1') && a:1 ? '--no-commit' : ''
    let edit = exists('a:2') && a:2 ? '--edit' : ''
    let signoff = exists('a:3') && a:3 ? '--signoff' : ''
    let attrib = exists('a:4') && a:4 ? '-x' : '-r'
    call s:GitRun('cherry-pick', nocommit, edit, signoff, attrib, shellescape(commit, 1))
    call s:GitGraphView()
endfunction

" a:1 = amend, a:2 = edit, a:3 = signoff, a:4 = message source: string/(f)ile/(c)ommit
function! s:GitCommit(msg, ...)
    let amend = exists('a:1') && a:1 ? '--amend' : ''
    let edit = exists('a:2') && a:2 ? '--edit' : ''
    let signoff = exists('a:3') && a:3 ? '--signoff' : ''
    let msgparam = exists('a:4') ? (a:4 == 'c' ? '-C' : (a:4 == 'f' ? '-F' : '-m')) : '-m'
    call s:GitRun('commit', amend, edit, signoff, msgparam, shellescape(a:msg, 1))
    call s:GitGraphView()
endfunction

" the same as GitCommit
function! s:GitCommitFiles(fname, msg, include, ...)
    if empty(a:fname) | return | endif
    let include = a:include ? '-i' : '-o'
    let files = s:ShellJoin(a:fname, ' ')
    let amend = exists('a:1') && a:1 ? '--amend' : ''
    let edit = exists('a:2') && a:2 ? '--edit' : ''
    let signoff = exists('a:3') && a:3 ? '--signoff' : ''
    let msgparam = exists('a:4') ? (a:4 == 'c' ? '-C' : (a:4 == 'f' ? '-F' : '-m')) : '-m'
    call s:GitRun('commit', amend, edit, signoff, msgparam, shellescape(a:msg, 1), include, '--', files)
    call s:GitGraphView()
endfunction

" a:1 = cached
" TODO: check options
function! s:GitApply(patch, ...)
    let cached = exists('a:1') && a:1 ? '--cached' : ''
    call s:GitRun('apply', cached, '--', a:patch)
    call s:GitStatusView()
endfunction

" }}}

call s:GitGraphInit()

" vim: et ts=8 sts=4 sw=4
