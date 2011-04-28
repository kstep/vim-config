colorscheme thegoodluck
set background=light
set guioptions=aier
set guifont=DejaVu\ Sans\ Mono\ 11
set noicon

sign define SyntasticError text=!! icon=/usr/share/icons/gnome/16x16/status/dialog-error.png
sign define SyntasticWarning text=>> icon=/usr/share/icons/gnome/16x16/status/dialog-warning.png

fun! GenGuiTabLabel()
    return GenTabLabel(v:lnum)
endfun

set guitablabel=%!GenGuiTabLabel()

