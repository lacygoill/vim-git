setl fdm=expr fde=getline(v:lnum)=~#'^commit'?'>1':'=' fdt=fold#fdt#get()

let b:undo_ftplugin ..= get(b:, 'undo_ftplugin', 'exe')..'|setl fdm< fde< fdt<'
