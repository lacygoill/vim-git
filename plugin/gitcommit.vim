if exists('g:loaded_gitcommit')
    finish
endif
let g:loaded_gitcommit = 1

call setenv('COMMIT_MESSAGES_DIR', $HOME..'/.vim/tmp/gitcommit_messages')
if !isdirectory($COMMIT_MESSAGES_DIR)
    call mkdir($COMMIT_MESSAGES_DIR, 'p', 0700)
endif

