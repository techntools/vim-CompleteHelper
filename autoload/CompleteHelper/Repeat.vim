" CompleteHelper/Repeat.vim: Generic functions to support repetition of custom insert mode completions.
"
" DEPENDENCIES:
"   - ingo/text.vim autoload script
"
" Copyright: (C) 2011-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.40.005	06-Apr-2014	I18N: Correctly handle repeats of (text ending
"				with a) multi-byte character: Instead of just
"				subtracting one from the column, ask for an
"				end-exclusive text grab from ingo#text#Get().
"   1.40.004	05-Apr-2014	Allow completion repeats to continue repeating
"				from following lines like the built-in
"				completions do: The newline plus any indent is
"				removed, and just the first word from the
"				following line is matched. For this, the
"				CompleteHelper#Repeat#Processor() is offered. It
"				transforms the leading whitespace of the match,
"				and manipulates the internal completion records
"				so that the original completion text is kept
"				(and therefore continues to match), even though
"				only the word itself has been inserted as a
"				completion candidate.
"				Allow to cancel repeats via
"				CompleteHelper#Repeat#Clear().
"   1.33.003	18-Dec-2013	Use ingo#text#Get() instead of
"				CompleteHelper#ExtractText().
"   1.11.002	01-Sep-2012	Make a:matchObj in CompleteHelper#ExtractText()
"				optional; it's not used there, anyway.
"   1.00.001	09-Oct-2011	file creation

let s:record = []
let s:startPos = []
let s:lastPos = []
let s:repeatCnt = 0
function! CompleteHelper#Repeat#SetRecord()
    let s:record = s:Record()
endfunction
function! CompleteHelper#Repeat#Clear()
    let s:record = []
endfunction
function! s:Record()
    return [tabpagenr(), winnr(), bufnr(''), b:changedtick, &completefunc] + getpos('.')
endfunction
function! CompleteHelper#Repeat#TestForRepeat()
    augroup CompleteHelperRepeat
	autocmd! CursorMovedI * call CompleteHelper#Repeat#SetRecord() | autocmd! CompleteHelperRepeat
    augroup END

    let l:pos = getpos('.')[1:2]
    if s:record == s:Record()
	if exists('s:moveStart')
	    " The inserted completion candidate differs in the whitespace (no
	    " newline and indent) from the original match position. To maintain
	    " the match, move the start position forward and instead store the
	    " so far completed text in s:previousText.
	    let s:previousText .= ingo#text#Get(s:startPos, s:lastPos, 1) . s:moveStart
"****D echomsg '****' string(s:previousText) string(s:startPos) '->' string(s:lastPos)
	    let l:newPos = [s:lastPos[0], s:lastPos[1] + 1] " I18N Note: Okay to simply add one to get to the character after the last completed match, as this will always be a Space character.
	    let s:startPos = l:newPos
	    unlet s:moveStart
	endif

	let s:repeatCnt += 1

	let l:addedText = ingo#text#Get(s:lastPos, l:pos, 1)
	let s:lastPos = l:pos

	let l:fullText = ingo#text#Get(s:startPos, l:pos, 1)

	return [s:repeatCnt, l:addedText, s:previousText . l:fullText]
    else
	let s:record = []
	unlet! s:moveStart
	let s:previousText = ''
	let l:base = call(&completefunc, [1, ''])
	let s:startPos = [line('.'), l:base + 1]
	let s:lastPos = s:startPos
	let s:repeatCnt = 0
	return [0, '', '']
    endif
endfunction

function! CompleteHelper#Repeat#Processor( text )
    " Condense a new line and the following indent to a single space to give a
    " continuous completion repeat just like the built-in repeat does.
    let l:textWithoutNewline = substitute(a:text, '^\s*\n\_s*', ' ', '')

    if l:textWithoutNewline !=# a:text
	" Because the completion candidate that will be inserted now differs
	" from the original match (there's no newline and indent any more),
	" further repeats wouldn't find any matches. Fix this by moving the
	" start position to the beginning of the last inserted match (without
	" the newline and indent), and move the repeatedly completed text to the
	" additional s:previousText assertion. This one needs to include the
	" newline and any leading indent before the text match in the new line.
	" Since this processor function is possibly invoked multiple times and
	" not in the buffer where the completion has been triggered, we just
	" record the removed whitespace here and do the actual shifting of the
	" text and positions on the next invocation of
	" CompleteHelper#Repeat#TestForRepeat().
	let s:moveStart = matchstr(a:text, '^\s*\n\_s*')
    endif

    return l:textWithoutNewline
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
