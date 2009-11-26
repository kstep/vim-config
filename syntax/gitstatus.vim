
" TODO syntax highlightng for git status view, commit view...
syn region gitStaged matchgroup=gitSectionHeader start='^# Changes to be committed:' end='^$' contains=gitModFile,gitNewFile,gitDelFile,gitRenFile fold
syn region gitUnstaged matchgroup=gitSectionHeader start='^# Changed but not updated:' end='^$' contains=gitModFile,gitNewFile,gitDelFile,gitRenFile fold
syn region gitUntracked matchgroup=gitSectionHeader start='^# Untracked files:' end='^$' contains=gitUnFile fold

syn region gitModFile start='^\t\[\*\]' end='$' contained
syn region gitNewFile start='^\t\[+\]' end='$' contained
syn region gitDelFile start='^\t\[-\]' end='$' contained
syn region gitRenFile start='^\t\[=\]' end='$' contained
syn region gitUnFile  start='^\t\[ \]' end='$' contained

hi link gitSectionHeader Title
hi link gitModFile Identifier
hi link gitNewFile Type
hi link gitRenFile Constant
hi link gitDelFile Special
hi link gitUnFile PreProc
