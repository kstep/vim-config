syn region gitlogHeaderZone start="^commit" end="^$" contains=gitlogCommittish,gitlogHeader,gitlogUserId,gitlogTimestamp,gitlogKeywords
syn match gitlogSvnId "git-svn-id: [a-z+]\{3,9}://[A-Za-z0-9./%@:_-]\{-1,}@[0-9]\+ [0-9a-f]\{8}\(-[0-9a-f]\{4}\)\{3}-[0-9a-f]\{12}"
syn match gitlogCommittish "\<[0-9a-f]\{5,40}\>" contained
syn match gitlogHeader "^[A-Z][a-z]\+: " contained
syn match gitlogUserId "<\S\+@\S\+>" contained
syn match gitlogTimestamp "\([A-Za-z]\{3} \)\{2}[0-9]\{1,2} \([0-9]\{2}:\)\{2}[0-9]\{2} [0-9]\{4} [+-][0-9]\{4}" contained
syn keyword gitlogKeywords commit contained

hi link gitlogCommittish Number
hi link gitlogSvnId Identifier
hi link gitlogHeader Keyword
hi link gitlogKeywords Keyword
hi link gitlogUserId Identifier
hi link gitlogTimestamp Special
