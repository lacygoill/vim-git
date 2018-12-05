" syntax {{{1

syn region gitconfigBackticks matchgroup=Comment start=/`/ end=/`/ oneline concealends containedin=gitconfigComment

" replace noisy markers, used in folds, with ❭ and ❬
exe 'syn match gitconfigFoldMarkers  /#\=\s*{'.'{{\d*\s*\ze\n/  conceal cchar=❭  containedin=gitconfigComment'
exe 'syn match gitconfigFoldMarkers  /#\=\s*}'.'}}\d*\s*\ze\n/  conceal cchar=❬  containedin=gitconfigComment'

" colors {{{1

hi link  gitconfigBackticks  Backticks

