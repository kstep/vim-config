syn region conflictRegion matchgroup=conflictMarker contains=conflictSep start="^<<<<<<<.*$" end="^>>>>>>>.*$" fold
syn match conflictSep "^=======$" contained

hi link conflictSep Error
hi link conflictMarker Error

