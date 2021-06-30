vim9script

if expand('<afile>:p')->fnamemodify(':t') == 'COMMIT_EDITMSG'
    if getline(1)->empty()
        gitcommit#readMessage()
    endif
    gitcommit#saveNextMessage('on_BufWinLeave')
endif

# Options {{{1

# Highlight the screen column right after `&textwidth`, so that we know when our commit
# message becomes too long.
&l:colorcolumn = '+1'

# Mappings {{{1

# If you need to customize some fugitive mappings, according to tpope,
# you need to listen to `FileType gitcommit` and check `&modifiable`.
#
# Source: https://github.com/tpope/vim-fugitive/issues/1076#issuecomment-412255667

# TODO: It would be nice to be able to fuzzy search through old commit messages.{{{
#
# Pressing `]m` and `[m`  can be ok if the message is right  before or after the
# one which is currently in the gitcommit buffer.
# But otherwise, it can be tedious to find the desired message.
#
# Once you do implement the fuzzy search, maybe get rid of `]m` and `[m`.
# This would  simplify the  code of  `gitcommit#readMessage()` which  would not
# accept an optional argument anymore.
#}}}
nnoremap <buffer><nowait> [m <Cmd>call gitcommit#readMessage(-1)<CR>
nnoremap <buffer><nowait> ]m <Cmd>call gitcommit#readMessage(+1)<CR>
nnoremap <buffer><nowait> dm <Cmd>call gitcommit#deleteCurrentMessage()<CR>

silent! repmap#make#repeatable({
    'mode': 'n',
    'buffer': true,
    'from': expand('<sfile>:p') .. ':' .. expand('<slnum>'),
    'motions': [
        {'bwd': '[m', 'fwd': ']m'},
]})

# Teardown {{{1

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'execute')
    .. '| call gitcommit#undoFtplugin()'

