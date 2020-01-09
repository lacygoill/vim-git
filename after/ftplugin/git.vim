" Rationale:{{{
"
" It is handy to fold the output of a command such as:
"
"     $ git log -L 97,98:file
"}}}
setl fdm=expr fde=getline(v:lnum)=~#'^commit'?'>1':'=' fdt=fold#fdt#get()

let b:undo_ftplugin ..= get(b:, 'undo_ftplugin', 'exe')..'|setl fdm< fde< fdt<'
