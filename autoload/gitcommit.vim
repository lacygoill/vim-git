vim9script noclear

# Interface {{{1
def gitcommit#deleteCurrentMessage() #{{{2
    if !exists('g:GITCOMMIT_LAST_MSGFILE')
        return
    endif
    if GetMsgfiles()->index(g:GITCOMMIT_LAST_MSGFILE) == -1
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
    var msgfiles: list<string> = GetMsgfiles()
    if empty(msgfiles)
        return
    endif

    var idx: number
    if !exists('g:GITCOMMIT_LAST_MSGFILE')
        idx = -1
    elseif offset != 0
        idx = index(msgfiles, g:GITCOMMIT_LAST_MSGFILE)
        if idx >= 0
            idx = (idx + offset) % len(msgfiles)
        endif
    else
        idx = index(msgfiles, g:GITCOMMIT_LAST_MSGFILE)
    endif
    g:GITCOMMIT_LAST_MSGFILE = msgfiles[idx]

    if filereadable(g:GITCOMMIT_LAST_MSGFILE)
        execute 'silent! keepjumps :1;/^' .. PAT .. '/-1 delete _'
        if !&modifiable
            &l:modifiable = true
        endif
        execute ':0 read ' .. g:GITCOMMIT_LAST_MSGFILE
        append("']", '')
        # need to write,  otherwise if we just execute `:x`,  git doesn't commit
        # because, for some reason, it thinks we didn't write anything
        silent write
    endif
enddef

def gitcommit#saveNextMessage(when: string) #{{{2
    if when =~ '\cBufWinLeave'
        augroup MyCommitMsgSave
            autocmd! * <buffer>
            autocmd BufWinLeave <buffer> gitcommit#saveNextMessage('now')
        augroup END
    else
        # Leave this statement at the very beginning.{{{
        #
        # If an error occurred in the function, the rest of the statements would
        # not be processed.  We want our autocmd to be cleared no matter what.
        #}}}
        silent! autocmd! MyCommitMsgSave * <buffer=abuf>

        cursor(1, 1)
        var msg_last_line: number = search('\S\_s*\n' .. PAT, 'nW')
        if msg_last_line > 0
            var msg: list<string> = getline(1, msg_last_line)
            var md5: string = GetMd5(msg)
            # save the message in a file if it has never been saved
            if readfile(CHECKSUM_FILE)->match('^\C' .. md5 .. '  ') == -1
                Write(msg, md5)
                g:GITCOMMIT_LAST_MSGFILE = -1
            endif
        endif
        MaybeRemoveOldestMsgfile()
    endif
enddef

def gitcommit#undoFtplugin() #{{{2
    set colorcolumn<

    nunmap <buffer> <C-S>
    nunmap <buffer> [m
    nunmap <buffer> ]m
    nunmap <buffer> dm
enddef
# }}}1
# Core {{{1
def MaybeRemoveOldestMsgfile() #{{{2
    var msgfiles: list<string> = GetMsgfiles()
    if len(msgfiles) > MAX_MESSAGES
        var oldest: string = msgfiles[0]
        delete(oldest)
    endif
enddef

def UpdateChecksumFile(arg_fname: string) #{{{2
    var fname: string = arg_fname->fnamemodify(':t')
    var new_checksums: list<string> = CHECKSUM_FILE
        ->readfile()
        ->filter((_, v: string): bool => v !~ '\C  ' .. fname .. '$')
        ->writefile(CHECKSUM_FILE)
enddef

def Write(msg: list<string>, md5: string) #{{{2
    # generate filename with current time and date
    var file: string = $COMMIT_MESSAGES_DIR .. '/' .. strftime(FMT) .. '.txt'
    # save message in a file
    writefile(msg, file)
    # update checksum file
    writefile([md5 .. '  ' .. file->fnamemodify(':t')], CHECKSUM_FILE, 'a')
enddef
# }}}1
# Utilities {{{1
def GetMsgfiles(): list<string> #{{{2
    return $COMMIT_MESSAGES_DIR
        ->readdir((n: string): bool => n =~ '\.txt$')
        ->map((_, v: string) => $COMMIT_MESSAGES_DIR .. '/' .. v)
enddef

def GetMd5(msg: list<string>): string #{{{2
    silent return ('md5sum <<< ' .. msg->join("\n")->string())
        ->system()
        ->matchstr('[a-f0-9]*')
enddef

def CreateChecksumFile() #{{{2
    # create the file
    writefile([], CHECKSUM_FILE)
    for file: string in GetMsgfiles()
        var msg: list<string> = readfile(file)
        var md5: string = GetMd5(msg)
        var m: string = md5 .. '  ' .. file->fnamemodify(':t')
        # append a line in the file for each past git commit message
        writefile([m], CHECKSUM_FILE, 'a')
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

