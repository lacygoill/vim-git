fu! gitcommit#read_last_message() abort "{{{1
    let file = $XDG_RUNTIME_VIM.'/last_commit_message'
    if filereadable(file)
        exe '0r '.file
        " need  to write,  otherwise if  we just  execute `:x`,  git doesn't  commit
        " because, for some reason, it thinks we didn't write anything
        w
    endif
endfu

fu! gitcommit#save_next_message(when) abort "{{{1
    if a:when is# 'on_bufwinleave'
        augroup my_commit_msg_save
            au! * <buffer>
            au BufWinLeave <buffer> call gitcommit#save_next_message('now')
        augroup END
    else
        let pat = '^# Please enter the commit message'
        if search(pat)
            exe 'keepj keepp 1;/'.pat.'/-2w! $XDG_RUNTIME_VIM/last_commit_message'
        endif
        au! my_commit_msg_save
        aug! my_commit_msg_save
    endif
endfu
