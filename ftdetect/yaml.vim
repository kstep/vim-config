fun! YamlDetect()
    if getline(1) =~ '^---$'
        setl ft=yaml
    endif
endfun
au BufReadPost * call YamlDetect()

