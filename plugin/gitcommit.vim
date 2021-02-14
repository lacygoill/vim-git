vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

setenv('COMMIT_MESSAGES_DIR', $HOME .. '/.vim/tmp/gitcommit_messages')
if !isdirectory($COMMIT_MESSAGES_DIR)
    mkdir($COMMIT_MESSAGES_DIR, 'p', 0o700)
endif

