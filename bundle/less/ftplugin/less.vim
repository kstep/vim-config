autocmd BufWritePost *.less silent! !lessc %:p %:p:r.css
