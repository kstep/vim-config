colorscheme peaksea
set background=dark
set guioptions=aeir
set guifont=Liberation\ Mono\ 11
set noicon

sign define SyntasticError text=!! icon=/usr/share/icons/gnome/16x16/status/dialog-error.png
sign define SyntasticWarning text=>> icon=/usr/share/icons/gnome/16x16/status/dialog-warning.png

fun! ConfigureXkb(use_caps_lock)
    silent !setxkbmap -option
    silent !setxkbmap -option terminate:ctrl_alt_bksp
    silent !setxkbmap -option compose:ralt
    if a:use_caps_lock
        silent !setxkbmap -option grp:caps_toggle
    endif
endfun

"call ConfigureXkb(0)
"au VimLeave * call ConfigureXkb(1)

