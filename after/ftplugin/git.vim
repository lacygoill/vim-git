" Rationale:{{{
"
" It is handy to fold the output of a command such as:
"
"     $ git log -L 97,98:file
"}}}
" Why should I *not* return `1` instead of `'='`?{{{
"
" It  would   cause  a  gitcommit  buffer   to  be  folded,  which   would  make
" `gitcommit#read_message()` initially remove more lines than intended:
"
"     sil! exe 'keepj 1;/^' .. s:PAT .. '/-d_'
"
" And now, because of that, when you  would cycle to another message, `:d` would
" fail to remove the old message because `s:PAT` could not be found anymore.
" As  a result,  every time  you would  cycle to  another message,  it would  be
" *appended* to the existing message(s) instead of replacing it/them.
"}}}
setl fdm=expr fde=getline(v:lnum)=~#'^commit'?'>1':'=' fdt=fold#fdt#get()

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe') .. '|setl fdm< fde< fdt<'
