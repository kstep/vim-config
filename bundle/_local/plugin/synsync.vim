fun! SetSyncMode()
    let fsize = getfsize(expand('%:p'))
    if fsize < 100*1024 " 100 Kb
        syn sync fromstart
    endif
endfun

aug SetSyncMode
    au!
    au BufRead * call SetSyncMode()
aug END
