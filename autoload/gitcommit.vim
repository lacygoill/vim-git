fu! gitcommit#backtick_minus(...) abort "{{{1
"                             │
"                             └ mode in which we want to map `-
"                               `n` by default
    " Why?{{{
    "
    " The function is going to recall itself, to map `- in visual mode too.
    " But, once it's done, it shouldn't recall itself anymore.
    " Otherwise, we would get an error (too recursive).
    "
    "     E132: Function call depth is higher than 'maxfuncdepth'
    "}}}
    if !empty(maparg('`-', 'x'))
        return
    endif

    let mode = a:0 ? a:1 : 'n'
    let minus_map = maparg('-', mode, 0, 1)
    if   !has_key(minus_map, 'rhs')
    \ || !has_key(minus_map, 'sid')
    \ || !get(minus_map, 'buffer', 0)
        return
    endif
    "                                             ┌ We could use just -, but if we press it
    "                                             │ on the wrong line, we may end up opening
    "                                             │ the file explorer.
    "                                             │
    exe printf(mode.'no <buffer><nowait><silent>  `-  %s',
    \           substitute(
    \               substitute(minus_map.rhs, '\c<sid>', '<snr>'.minus_map.sid.'_', 'g'),
    \           '|', '<bar>', 'g'))

    call gitcommit#backtick_minus('x')
endfu

fu! gitcommit#read_last_message() abort "{{{1
    let file = $XDG_RUNTIME_VIM.'/last_commit_message'
    if filereadable(file)
        exe '0r '.file
        " need  to write,  otherwise if  we just  execute `:x`,  git doesn't  commit
        " because, for some reason, it thinks we didn't write anything
        w
    endif
endfu

fu! gitcommit#save_next_message() abort "{{{1
    augroup my_commit_msg_save
        au! * <buffer>
        au BufWinLeave <buffer> keepj keepp 1;/^# Please enter the commit message/-2w! $XDG_RUNTIME_VIM/last_commit_message
        \ |                     exe 'au! my_commit_msg_save'
        \ |                     exe 'aug! my_commit_msg_save'
    augroup END
endfu
