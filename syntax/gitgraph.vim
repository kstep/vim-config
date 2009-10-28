syn match gitgraphTree "^[ 0-9\|/*]\+\( [0-9a-f]\{7,40}\)\?\( ([:.a-zA-Z0-9_/, -]\+)\)\?\( \[[^]]\+\]\)\? " contains=gitgraphTree1,gitgraphTree2,gitgraphTree3,gitgraphTree4,gitgraphTree5,gitgraphTree6,gitgraphTree7,gitgraphTree8,gitgraphTree9,gitgraphTreeC,gitgraphCommittish,gitgraphRefsList,gitgraphAuthor

syn match gitgraphCommittish "\<[0-9a-f]\{7,40}\>" nextgroup=gitgraphRefsList contained

syn region gitgraphRefsList start="(" end=")" contains=gitgraphRefItem,gitgraphRemoteItem,gitgraphTagItem,gitgraphStashItem,gitgraphRefSep contained
syn match gitgraphRefItem "[.a-zA-Z0-9_/-]\+" nextgroup=gitgraphRefSep contained
syn match gitgraphTagItem "tag:[.a-zA-Z0-9_/-]\+" nextgroup=gitgraphRefSep contained
syn match gitgraphRemoteItem "remote:[.a-zA-Z0-9_/-]\+" nextgroup=gitgraphRefSep contained
syn keyword gitgraphStashItem stash nextgroup=gitgraphRefSep contained
syn match gitgraphRefSep ", " nextgroup=gitgraphRefItem,gitgraphTagItem,gitgraphStashItem,gitgraphRemoteItem contained

syn match gitgraphAuthor "\[.*\]" contained

syn match gitgraphTree1 "1[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTree2 "2[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTree3 "3[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTree4 "4[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTree5 "5[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTree6 "6[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTree7 "7[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTree8 "8[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTree9 "9[\|/]" contained contains=gitgraphTreeMarker
syn match gitgraphTreeC " \*" contained
syn match gitgraphTreeMarker "[0-9]" contained

syn keyword gitgraphKeywords Merge

hi link gitgraphTree Special
hi link gitgraphCommittish Identifier

hi link gitgraphRefsList String
hi link gitgraphRefItem Label
hi link gitgraphStashItem Todo
hi link gitgraphTagItem Tag
hi link gitgraphRemoteItem Include
hi link gitgraphRefSep Delimiter
hi link gitgraphKeywords Keyword
hi link gitgraphAuthor Constant

hi gitgraphTree1 ctermfg=1 guifg=blue
hi gitgraphTree2 ctermfg=2 guifg=green
hi gitgraphTree3 ctermfg=3 guifg=cyan
hi gitgraphTree4 ctermfg=4 guifg=red
hi gitgraphTree5 ctermfg=5 guifg=magenta
hi gitgraphTree6 ctermfg=6 guifg=brown
hi gitgraphTree7 ctermfg=7 guifg=white
hi gitgraphTree8 ctermfg=8 guifg=yellow
hi gitgraphTree9 ctermfg=9 guifg=purple
hi link gitgraphTreeC SpecialChar
hi link gitgraphTreeMarker Ignore

