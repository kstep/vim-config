"let test_path = "pk/vi/plu/c"

function! ZshLikeComplete(path, cmd, pos)
    "if len(a:path) < 1 | return [ expand('%:p:h'), expand('%:p') ] | endif
    let parts = split((len(a:path) > 0)? (a:path): expand('%:p:h'), '/', 1)
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

    return map(variants, 'escape(v:val, " \\")')
endfun

function! ZshCmplWrap(alias, cmd)
    exec 'command! -complete=customlist,ZshLikeComplete -nargs=? ' . a:alias . ' ' . a:cmd . ' <args>'
endfun

for [alias, cmd] in [
            \['E', 'edit'],
            \['T', 'tabedit'],
            \['S', 'split'],
            \['V', 'vsplit'],
            \['R', 'read']
            \]
    call ZshCmplWrap(alias, cmd)
endfor

"echo ZshLikeComplete(test_path, '', 0)

