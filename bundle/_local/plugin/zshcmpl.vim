"let test_path = "pk/vi/plu/c"

function! ZshLikeComplete(path, cmd, pos)
    let parts = split(a:path, '/', 1)
    let variants = (parts[0] == '~' || parts[0] == '.' || parts[0] == '..' || parts[0] == '') ?
                \ remove(parts, 0, 0) :
                \ split(globpath(&path, remove(parts, 0).'*'), '\n')

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

