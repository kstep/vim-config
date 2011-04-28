function! Todo(ext)
    let old_makeprg = &makeprg
    let old_efm = &errorformat
    let &makeprg = 'find ' . substitute(&path, ',', ' ', 'g') . ' -type f -name "*.' . a:ext . '" -exec grep -EHn "TODO\|FIXME\|XXX" {} + \| sed "/XXX/s/^/N:/; /FIXME/s/^/E:/; /TODO/s/^/W:/"'
    let &errorformat = '%t:%f:%l:%m'
    silent make
    copen
    let &makeprg = old_makeprg
    let &errorformat = old_efm
endfunction

command! -nargs=1 Todo call Todo(<f-args>)
