if exists('g:autoloaded_gitcommit')
    finish
endif
let g:autoloaded_gitcommit = 1

" Interface {{{1
fu gitcommit#delete_current_message(...) abort "{{{2
    if !exists('g:GITCOMMIT_LAST_MSGFILE') | return | endif
    let msgfiles = glob($COMMIT_MESSAGES_DIR..'/*.txt', 0, 1)
    if index(msgfiles, g:GITCOMMIT_LAST_MSGFILE) == -1 | return | endif

    let fname = g:GITCOMMIT_LAST_MSGFILE

    " import next message file
    call gitcommit#read_message(+1)

    " remove previous message file
    call delete(fname)

    call s:update_checksum_file(fname)
endfu

fu gitcommit#read_message(...) abort "{{{2
    let msgfiles = glob($COMMIT_MESSAGES_DIR..'/*.txt', 0, 1)
    if empty(msgfiles) | return | endif

    if !exists('g:GITCOMMIT_LAST_MSGFILE')
        let idx = -1
    elseif a:0
        let idx = index(msgfiles, g:GITCOMMIT_LAST_MSGFILE)
        if idx != -1
            let idx = (idx + a:1) % len(msgfiles)
        endif
    else
        let idx = index(msgfiles, g:GITCOMMIT_LAST_MSGFILE)
    endif
    let g:GITCOMMIT_LAST_MSGFILE = msgfiles[idx]

    if filereadable(g:GITCOMMIT_LAST_MSGFILE)
        sil! exe 'keepj 1;/^'..s:PAT..'/-d_'
        if !&modifiable | setl modifiable | endif
        exe '0r '..g:GITCOMMIT_LAST_MSGFILE
        call append("']", '')
        " need to write,  otherwise if we just execute `:x`,  git doesn't commit
        " because, for some reason, it thinks we didn't write anything
        sil w
    endif
endfu

fu gitcommit#save_next_message(when) abort "{{{2
    if a:when is# 'on_bufwinleave'
        augroup my_commit_msg_save
            au! * <buffer>
            au BufWinLeave <buffer> call gitcommit#save_next_message('now')
        augroup END
    else
        " Leave this statement at the very beginning.{{{
        "
        " If an error occurred in the function,  because of `abort`, the rest of the
        " statements would not be processed.
        " We want our autocmd to be cleared no matter what.
        "}}}
        sil! au! my_commit_msg_save * <buffer>

        call cursor(1,1)
        let msg_last_line = search('\S\_s*\n'..s:PAT, 'nW')
        if msg_last_line
            let msg = getline(1, msg_last_line)
            let md5 = s:get_md5(msg)
            " save the message in a file if it has never been saved
            if match(readfile(s:CHECKSUM_FILE), '\m\C^'..md5..'  ') == -1
                call s:write(msg, md5)
            endif
        endif
        call s:maybe_remove_oldest_msgfile()
    endif
endfu

fu gitcommit#undo_ftplugin() abort "{{{2
    setl cc<

    nunmap <buffer> <c-s>
    nunmap <buffer> [m
    nunmap <buffer> ]m
    nunmap <buffer> dm
endfu
" }}}1
" Core {{{1
fu s:maybe_remove_oldest_msgfile() abort "{{{2
    let msgfiles = glob($COMMIT_MESSAGES_DIR..'/*.txt', 0, 1)
    if len(msgfiles) > s:MAX_MESSAGES
        let oldest = msgfiles[0]
        call delete(oldest)
    endif
endfu

fu s:update_checksum_file(fname, ...) abort "{{{2
    let fname = fnamemodify(a:fname, ':t')
    let new_checksums = readfile(s:CHECKSUM_FILE)
    call filter(new_checksums, {_,v -> v !~# '\m\C  '..fname..'$'})
    call writefile(new_checksums, s:CHECKSUM_FILE)
endfu

fu s:write(msg, md5) abort "{{{2
    " generate filename with current time and date
    let file = $COMMIT_MESSAGES_DIR..'/'..strftime(s:FMT)..'.txt'
    " save message in a file
    call writefile(a:msg, file)
    " update checksum file
    call writefile([a:md5..'  '..fnamemodify(file, ':t')],
        \ s:CHECKSUM_FILE, 'a')
endfu
" }}}1
" Utilities {{{1
fu s:get_md5(msg) abort "{{{2
    sil let md5 = system('md5sum <<< '..string(join(a:msg, "\n")))
    let md5 = matchstr(md5, '[a-f0-9]*')
    return md5
endfu

fu s:create_checksum_file() abort "{{{2
    for file in glob($COMMIT_MESSAGES_DIR..'/*.txt', 0, 1)
        let msg = readfile(file)
        let md5 = s:get_md5(msg)
        let file = fnamemodify(file, ':t')
        call writefile([md5..'  '..file], s:CHECKSUM_FILE, 'a')
    endfor
endfu
"}}}1
" Init {{{1

" The init section needs to be at the end because it calls `s:create_checksum_file()`.
" The function must exist.

const s:PAT = '# Please enter the commit message'
const s:MAX_MESSAGES = 100
" Isn't `%S` overkill?{{{
"
" No, we need the seconds in a file title to avoid overwriting a message file if
" we commit twice in less than a minute.
"}}}
const s:FMT = '%Y-%m-%d__%H-%M-%S'
const s:CHECKSUM_FILE = $COMMIT_MESSAGES_DIR..'/checksums'
if !filereadable(s:CHECKSUM_FILE) | call s:create_checksum_file() | endif

