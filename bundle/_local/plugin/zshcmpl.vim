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

function! ZshCmplWrap(alias, cmd)
    exec 'command! -complete=customlist,ZshLikeComplete -nargs=? ' . a:alias . ' ' . a:cmd . ' <args>'
endfun

for [alias, cmd] in [
            \['E', 'edit'],
            \['TE', 'tabedit'],
            \['S', 'split'],
            \['SV', 'vsplit'],
            \['R', 'read']
            \]
    call ZshCmplWrap(alias, cmd)
endfor

"echo ZshLikeComplete(test_path, '', 0)

