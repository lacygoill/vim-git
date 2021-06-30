vim9script

# Rationale:{{{
#
# It is handy to fold the output of a command such as:
#
#     $ git log -L 97,98:file
#}}}
# Why should I *not* return `1` instead of `'='`?{{{
#
# It  would   cause  a  gitcommit  buffer   to  be  folded,  which   would  make
# `gitcommit#readMessage()` initially remove more lines than intended:
#
#     execute 'silent! keepjumps :1;/^' .. PAT .. '/-1 delete _'
#
# And now, because  of that, when you would cycle  to another message, `:delete`
# would fail to remove the old message because `PAT` could not be found anymore.
# As  a result,  every time  you would  cycle to  another message,  it would  be
# *appended* to the existing message(s) instead of replacing it/them.
#}}}
&l:foldmethod = 'expr'
&l:foldexpr = "getline(v:lnum)=~'^commit'?'>1':'='"
&l:foldtext = 'fold#foldtext#get()'

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'execute')
    .. '| set foldmethod< foldexpr< foldtext<'
