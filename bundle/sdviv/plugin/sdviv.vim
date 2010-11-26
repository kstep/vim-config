
if !executable('sdcv')
    finish
endif

fun! Translate(word)
    let word = system('sdcv -n ' . a:word)
    return word
endfun

fun! WinTranslate(word)
    let word = Translate(a:word)
    if word == '' || word =~# 'Ничего похожего на'
        echoerr "No translation found!"
        return
    endif

    silent new
    silent put =word
    silent exec 'file "Translation for '.a:word.'"'
    silent setl nomodified nomodifiable filetype=sdviv
    silent 1
endfun

map <Leader>t :call WinTranslate(expand('<cword>'))<cr>

