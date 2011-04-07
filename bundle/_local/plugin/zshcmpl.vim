"let test_path = "~/pk/vi/plu/c"

function! ZshLikeComplete(path, cmd, pos)
    let parts = split(a:path, '/', 1)
    let variants = [remove(parts, 0)]

    for part in parts
        let newvars = []
        for variant in variants
            let newvars = extend(newvars, split(glob(variant.'/'.part.'*'), '\n'))
        endfor
        let variants = newvars
        if len(variants) < 1 | break | endif
    endfor

    return variants
endfun

command! -complete=customlist,ZshLikeComplete -nargs=1 E edit <args>
command! -complete=customlist,ZshLikeComplete -nargs=1 TE tabedit <args>

"echo ZshLikeComplete(test_path, '', 0)

