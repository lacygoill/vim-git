" Rationale:{{{
"
" It is handy to fold the output of a command such as:
"
"     $ git log -L 97,98:file
"}}}
" Why should I *not* return `1` instead of `'='`?{{{
"
" It  would   cause  a  gitcommit  buffer   to  be  folded,  which   would  make
" `gitcommit#readMessage()` initially remove more lines than intended:
"
"     exe 'sil! keepj :1;/^' .. PAT .. '/-d _'
"
" And now, because of that, when you  would cycle to another message, `:d` would
" fail to remove the old message because `PAT` could not be found anymore.
" As  a result,  every time  you would  cycle to  another message,  it would  be
" *appended* to the existing message(s) instead of replacing it/them.
"}}}
setl fdm=expr fde=getline(v:lnum)=~#'^commit'?'>1':'=' fdt=fold#fdt#get()

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe') .. '| set fdm< fde< fdt<'
