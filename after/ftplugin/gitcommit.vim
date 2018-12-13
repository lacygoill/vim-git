if fnamemodify(expand('%:p'), ':t') is# 'COMMIT_EDITMSG'
    if empty(getline(1))
        call gitcommit#read_last_message()
    endif
    call gitcommit#save_next_message('on_bufwinleave')
endif

" Options {{{1

" Highlight the screen column right after `&tw`, so that we know when our commit
" message becomes too long.
setl cc=+1

" Mappings {{{1

" If you need to customize some fugitive mappings, according to tpope,
" you need to listen to `FileType gitcommit` and check `&modifiable`.
"
" Source:
"     https://github.com/tpope/vim-fugitive/issues/1076#issuecomment-412255667

" Why?{{{
"
" To save a buffer, we use a mapping like this:
"
"     nno  <silent>  <c-s>  :call Func()<cr>
"     fu! Func()
"         sil update
"     endfu
"
" Pb:
"
" For some reason, when we save, the current line becomes temporarily concealed.
" It reappears after we move the cursor on a different line.
" The problem seems to come from an interaction between:
"
"         :silent
"         <silent>
"         a git commit buffer
"         vim-gutentags ? (not sure about this one)
"
" Solution:
" Define a simpler buffer-local mapping which doesn't use `:silent`.
"}}}
nno  <buffer><nowait><silent>  <c-s>  :<c-u>update<cr>

nno  <buffer><nowait><silent>  [m  :<c-u>call gitcommit#read_last_message(-1)<cr>
nno  <buffer><nowait><silent>  ]m  :<c-u>call gitcommit#read_last_message(+1)<cr>
nno  <buffer><nowait><silent>  dm  :<c-u>call gitcommit#delete_current_message()<cr>

if stridx(&rtp, 'vim-lg-lib') >= 0
    call lg#motion#repeatable#make#all({
        \ 'mode': '',
        \ 'buffer': 1,
        \ 'axis': {'bwd': ',', 'fwd': ';'},
        \ 'from': expand('<sfile>:p').':'.expand('<slnum>'),
        \ 'motions': [
        \     {'bwd': '[m',  'fwd': ']m'},
        \ ]})
endif

" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
    \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
    \ . "
    \   setl cc<
    \ | unlet! b:msg_index
    \
    \ | exe 'nunmap <buffer> <c-s>'
    \ | exe 'nunmap <buffer> [m'
    \ | exe 'nunmap <buffer> ]m'
    \ | exe 'nunmap <buffer> dm'
    \ "

