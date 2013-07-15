setl ts=8
setl sws=4
setl sw=4
setl et
setl pa=.,..,../..,../../..,../../../..,../../../../..,../../../../../..
setl inex=substitute(v:fname,'\\.','/','g').'.py'
setl mp=python\ %:p
setl efm=%C%p^,%A\ %#File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m,%+C\ %s
setl fdm=indent
setl cc=120 tw=110

"inoremap <buffer> _( _(u'')<Left><Left>
inoremap ''' '''<CR>'''<Up><CR>
