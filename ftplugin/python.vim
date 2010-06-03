setl ts=8
setl sws=4
setl sw=4
setl et
setl pa=.,..,../..,../../..,../../../..,../../../../..,../../../../../..
setl inex=substitute(v:fname,'\\.','/','g').'.py'
setl mp=python\ %:p
setl efm=%C%p^,%A\ %#File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m,%+C\ %s

inoremap <buffer> _( _(u'')<Left><Left>
