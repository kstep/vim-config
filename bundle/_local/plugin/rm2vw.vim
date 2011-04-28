function! s:Redmine2VimwikiHeaders()
    %s/^h\([1-6]\)\. \(.\+\)$/\=repeat('=', submatch(1)).' '.submatch(2).' '.repeat('=', submatch(1))/
endfun

function! s:Redmine2VimwikiMacros()
    %s/^{{\(\w\+\)}}$/%\1/
endfun

function! s:Redmine2VimwikiBulletLists()
    %s/^\(\**\)\{-}\* /\=repeat('    ', len(submatch(1))).'* '/
endfun

function! Redmine2Vimwiki()
    silent call s:Redmine2VimwikiHeaders()
    silent call s:Redmine2VimwikiMacros()
    silent call s:Redmine2VimwikiBulletLists()
endfun

function! s:Vimwiki2RedmineHeaders()
    %s/^\(=\+\) \(.\{-1,}\) \1/\='h'.len(submatch(1)).'. '.submatch(2)/
endfun

function! s:Vimwiki2RedmineMacros()
    %s/^%\(\w\+\)$/{{\1}}/
endfun

function! s:Vimwiki2RedmineBulletLists()
    %s_^\( *\)\* _\=repeat('*', len(submatch(1)) / &shiftwidth).'* '_
endfun

function! Vimwiki2Redmine()
    silent call s:Vimwiki2RedmineHeaders()
    silent call s:Vimwiki2RedmineMacros()
    silent call s:Vimwiki2RedmineBulletLists()
endfun

command! -nargs=0 Vimwiki2Redmine call Vimwiki2Redmine()
command! -nargs=0 Redmine2Vimwiki call Redmine2Vimwiki()

