vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def gitcommit#deleteCurrentMessage() #{{{2
    if !exists('g:GITCOMMIT_LAST_MSGFILE')
        return
    endif
    var msgfiles: list<string> = glob($COMMIT_MESSAGES_DIR .. '/*.txt', false, true)
    if index(msgfiles, g:GITCOMMIT_LAST_MSGFILE) == -1
        return
    endif

    var fname: string = g:GITCOMMIT_LAST_MSGFILE

    # import next message file
    gitcommit#readMessage(+1)

    # remove previous message file
    delete(fname)

    UpdateChecksumFile(fname)
enddef

def gitcommit#readMessage(offset = 0) #{{{2
    var msgfiles: list<string> = glob($COMMIT_MESSAGES_DIR .. '/*.txt', false, true)
    if empty(msgfiles)
        return
    endif

    var idx: number
    if !exists('g:GITCOMMIT_LAST_MSGFILE')
        idx = -1
    elseif offset != 0
        idx = index(msgfiles, g:GITCOMMIT_LAST_MSGFILE)
        if idx != -1
            idx = (idx + offset) % len(msgfiles)
        endif
    else
        idx = index(msgfiles, g:GITCOMMIT_LAST_MSGFILE)
    endif
    g:GITCOMMIT_LAST_MSGFILE = msgfiles[idx]

    if filereadable(g:GITCOMMIT_LAST_MSGFILE)
        sil! exe 'keepj :1;/^' .. PAT .. '/-d _'
        if !&modifiable
            setl modifiable
        endif
        exe ':0r ' .. g:GITCOMMIT_LAST_MSGFILE
        append("']", '')
        # need to write,  otherwise if we just execute `:x`,  git doesn't commit
        # because, for some reason, it thinks we didn't write anything
        sil w
    endif
enddef

def gitcommit#saveNextMessage(when: string) #{{{2
    if when == 'on_bufwinleave'
        augroup MyCommitMsgSave
            au! * <buffer>
            au BufWinLeave <buffer> gitcommit#saveNextMessage('now')
        augroup END
    else
        # Leave this statement at the very beginning.{{{
        #
        # If an error occurred in the function,  because of `abort`, the rest of the
        # statements would not be processed.
        # We want our autocmd to be cleared no matter what.
        #}}}
        sil! au! MyCommitMsgSave * <buffer>

        cursor(1, 1)
        var msg_last_line: number = search('\S\_s*\n' .. PAT, 'nW')
        if msg_last_line != 0
            var msg: list<string> = getline(1, msg_last_line)
            var md5: string = GetMd5(msg)
            # save the message in a file if it has never been saved
            if readfile(CHECKSUM_FILE)->match('\m\C^' .. md5 .. '  ') == -1
                Write(msg, md5)
            endif
        endif
        MaybeRemoveOldestMsgfile()
    endif
enddef

def gitcommit#undoFtplugin() #{{{2
    set cc<

    nunmap <buffer> <c-s>
    nunmap <buffer> [m
    nunmap <buffer> ]m
    nunmap <buffer> dm
enddef
# }}}1
# Core {{{1
def MaybeRemoveOldestMsgfile() #{{{2
    var msgfiles: list<string> = glob($COMMIT_MESSAGES_DIR .. '/*.txt', false, true)
    if len(msgfiles) > MAX_MESSAGES
        var oldest: string = msgfiles[0]
        delete(oldest)
    endif
enddef

def UpdateChecksumFile(arg_fname: string) #{{{2
    var fname: string = fnamemodify(arg_fname, ':t')
    var new_checksums: list<string> = readfile(CHECKSUM_FILE)
    filter(new_checksums, (_, v) => v !~ '\m\C  ' .. fname .. '$')
    writefile(new_checksums, CHECKSUM_FILE)
enddef

def Write(msg: list<string>, md5: string) #{{{2
    # generate filename with current time and date
    var file: string = $COMMIT_MESSAGES_DIR .. '/' .. strftime(FMT) .. '.txt'
    # save message in a file
    writefile(msg, file)
    # update checksum file
    writefile([md5 .. '  ' .. fnamemodify(file, ':t')], CHECKSUM_FILE, 'a')
enddef
# }}}1
# Utilities {{{1
def GetMd5(msg: list<string>): string #{{{2
    sil return ('md5sum <<< ' .. join(msg, "\n")->string())
        ->system()
        ->matchstr('[a-f0-9]*')
enddef

def CreateChecksumFile() #{{{2
    for file in glob($COMMIT_MESSAGES_DIR .. '/*.txt', false, true)
        var msg: list<string> = readfile(file)
        var md5: string = GetMd5(msg)
        var file: string = fnamemodify(file, ':t')
        writefile([md5 .. '  ' .. file], CHECKSUM_FILE, 'a')
    endfor
enddef
#}}}1
# Init {{{1

# The init section needs to be at the end because it calls `CreateChecksumFile()`.
# The function must exist.

const PAT: string = '# Please enter the commit message'
const MAX_MESSAGES: number = 100
# Isn't `%S` overkill?{{{
#
# No, we need the seconds in a file title to avoid overwriting a message file if
# we commit twice in less than a minute.
#}}}
const FMT: string = '%Y-%m-%d__%H-%M-%S'
const CHECKSUM_FILE: string = $COMMIT_MESSAGES_DIR .. '/checksums'
if !filereadable(CHECKSUM_FILE)
    CreateChecksumFile()
endif

