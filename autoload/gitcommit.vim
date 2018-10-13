if exists('g:autoloaded_gitcommit')
    finish
endif
let g:autoloaded_gitcommit = 1

let s:PAT = '# Please enter the commit message'
let s:MAX_MESSAGES = 100

" Interface {{{1
fu! gitcommit#read_last_message(...) abort "{{{2
    let messages = glob($COMMIT_MESSAGES_DIR.'/*.txt', 0, 1)
    let b:msg_index = !a:0
        \ ?     -1
        \ : !exists('b:msg_index')
        \ ?     a:1 - 1
        \ :     (b:msg_index + a:1) % len(messages)

    let msg = get(messages, b:msg_index, '')
    if filereadable(msg)
        sil! exe '1;/^'.s:PAT.'/-d_'
        exe '0r '.msg
        call append("']", '')
        " need to write,  otherwise if we just execute `:x`,  git doesn't commit
        " because, for some reason, it thinks we didn't write anything
        w
    endif
endfu

fu! gitcommit#save_next_message(when) abort "{{{2
    if a:when is# 'on_bufwinleave'
        augroup my_commit_msg_save
            au! * <buffer>
            au BufWinLeave <buffer> call gitcommit#save_next_message('now')
        augroup END
    else
        let last_line = search('^.*\S.*\%(\s*\n\)*'.s:PAT)
        if last_line
            let msg = getline(1, last_line)
            let md5 = s:get_md5(msg)
            let checksum_file = $COMMIT_MESSAGES_DIR.'/checksums'
            "  ┌ there's no checksums file{{{
            "  │                               ┌ there's already a file storing this message
            "  │                               │}}}
            if !filereadable(checksum_file) || match(readfile(checksum_file), md5) == -1
                call s:write(msg, md5, checksum_file)
            endif
        endif
        sil! au! my_commit_msg_save * <buffer>
        call s:maybe_remove_oldest()
    endif
endfu

" Core {{{1
fu! s:maybe_remove_oldest() abort "{{{2
    let messages = glob($COMMIT_MESSAGES_DIR.'/*.txt', 0, 1)
    if len(messages) > s:MAX_MESSAGES
        let oldest = messages[0]
        call delete(oldest)
    endif
endfu

fu! s:write(msg, md5, checksum_file) abort "{{{2
    " we need the seconds in the file title to avoid overwriting a message
    " if we make 2 commits in less than a minute
    let file = $COMMIT_MESSAGES_DIR.'/'.strftime('%m-%d__%H-%M-%S').'.txt'
    call writefile(a:msg, file)
    call writefile([a:md5.'  '.fnamemodify(file, ':t')],
        \ a:checksum_file, 'a')
endfu

" Utility {{{1
fu! s:get_md5(msg) abort "{{{2
    let md5 = system('md5sum <<< '.string(join(a:msg, "\n")))
    let md5 = matchstr(md5, '[a-f0-9]*')
    return md5
endfu

