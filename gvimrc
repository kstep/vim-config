colorscheme xoria256
"colorscheme thegoodluck
"colorscheme chocolate
set background=dark
set guioptions=aie
set guifont=DejaVu\ Sans\ Mono\ 11
set noicon

let g:indent_guides_enable_on_vim_startup = 1

sign define SyntasticError text=!! icon=/usr/share/icons/gnome/16x16/status/dialog-error.png
sign define SyntasticWarning text=>> icon=/usr/share/icons/gnome/16x16/status/dialog-warning.png

fun! GenGuiTabLabel()
    return GenTabLabel(v:lnum)
endfun

set guitablabel=%!GenGuiTabLabel()

