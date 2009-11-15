
" TODO syntax highlightng for git status view, commit view...
syn region gitStaged matchgroup=gitSectionHeader start='^# Changes to be committed:' end='^$' contains=gitModFile,gitNewFile,gitDelFile fold
syn region gitUnstaged matchgroup=gitSectionHeader start='^# Changed but not updated:' end='^$' contains=gitModFile,gitNewFile,gitDelFile fold
syn region gitUntracked matchgroup=gitSectionHeader start='^# Untracked files:' end='^$' contains=gitUnFile fold

syn region gitModFile start='^\t\[\*\]' end='$' contained
syn region gitNewFile start='^\t\[+\]' end='$' contained
syn region gitDelFile start='^\t\[-\]' end='$' contained
syn region gitUnFile  start='^\t\[ \]' end='$' contained

hi link gitSectionHeader Title
hi gitModFile guifg=#eeee00
hi gitNewFile guifg=#00ee00
hi gitDelFile guifg=#ee0000
hi gitUnFile guifg=#00eeee
