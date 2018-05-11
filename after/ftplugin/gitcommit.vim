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

" What does `-` do in a gitcommit buffer?{{{
"
" `fugitive` installs  a buffer-local mapping  using the  lhs `-` in  the window
" opened by  `:Gstatus`. Its purpose  is to  stage or unstage  the files  in the
" current git repo.
"}}}
" Does it work anywhere?{{{
"
" No. Only when you're on the line:
"
"     # Changes not staged for commit:
" or:
"     # Changes to be committed:
"}}}
" Why remapping it?{{{
"
" Unfortunately, it wasn't given the `<nowait>` argument, so it suffers
" from a timeout because of our `--` (open file explorer) mapping.
"
" We need to remap it, but it seems tricky.
" We can't listen to FileType because the mapping is not installed yet,
" so `maparg(…)` is empty.
"}}}
call timer_start(0, {-> gitcommit#backtick_minus()})
" Is there an alternative to the timer?{{{
"
" Maybe.
" You could try and install a fire-once autocmd listening to `BufWinEnter`.
"
" Read this:
"
"     https://vi.stackexchange.com/a/8587/15612
"}}}

" Teardown {{{1

let b:undo_ftplugin =         get(b:, 'undo_ftplugin', '')
\                     .(empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
\                     ."
\                         setl cc<
\                       | exe 'nunmap <buffer> <c-s>'
\                      "
