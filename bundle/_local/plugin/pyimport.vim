
function! s:PythonAddImport(defname)
python <<EOP
def python_add_import(defname):
    import vim
    import sys
    import os

    def get_tag_file(defname):
        try:
            return vim.eval('taglist("%s")' % defname)[0]['filename']
        except (IndexError, KeyError):
            return None

    def get_mod_name(fname):
        for path in sys.path:
            if fname.startswith(path):
                fname, _ = os.path.splitext(fname)
                fname = fname[len(path):].strip('/').replace('/', '.')
                return fname

    modname = None
    tagfile = get_tag_file(defname)

    if tagfile:
        modname = get_mod_name(tagfile)

    if not modname:
        return

    buf = vim.current.buffer
    importexpr = 'from %s import' % (modname)
    lineno = 2
    for i, line in enumerate(buf):
        if line.startswith(('from ', 'import ')):
            lineno = i + 1
            if line.startswith(importexpr):
                break

    vim.current.buffer.append('%s %s' % (importexpr, defname), lineno)

python_add_import(vim.eval('a:defname'))
EOP
endfun

command! -nargs=1 PythonAddImport call <SID>PythonAddImport(<f-args>)
noremap <silent> <Plug>PythonAddImport :call <SID>PythonAddImport(expand('<cword>'))<CR>
map ,i <Plug>PythonAddImport

