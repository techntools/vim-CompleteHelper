" CompleteHelper.vim: Generic functions to support custom insert mode completions.
"
" DEPENDENCIES:
"   - CompleteHelper/Abbreviate.vim autoload script
"   - ingo/compat.vim autoload script
"   - ingo/compat/window.vim autoload script
"   - ingo/list.vim autoload script
"   - ingo/pos.vim autoload script
"   - ingo/text.vim autoload script
"   - ingo/workingdir.vim autoload script
"
" Copyright: (C) 2008-2021 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

if ! exists('g:CompleteHelper_IsDefaultToBackwardSearch')
    let g:CompleteHelper_IsDefaultToBackwardSearch = 1
endif

function! CompleteHelper#FindMatches( matches, pattern, options, matchTemplate={}, isInCompletionWindow=1 )
"*******************************************************************************
"* PURPOSE:
"   Find matches for a:pattern according to a:options and store them in
"   a:matches.
"* ASSUMPTIONS / PRECONDITIONS:
"   none
"* EFFECTS / POSTCONDITIONS:
"   none
"* INPUTS:
"   a:matches	(Empty) List that will hold the matches (in Dictionary format,
"		cp. :help complete-functions). Matches will be appended.
"   a:pattern	Regular expression specifying what text will match as a
"		completion candidate.
"		If you have multiple regular expressions that can match at the
"		same position and should yield separate matches, you cannot use
"		regular expression branches. Instead, pass a List of regular
"		expressions for a:pattern.
"		Note: In the buffer where the completion takes place, Vim
"		temporarily removes the a:base part (as passed to the
"		complete-function) during the completion. This helps avoiding
"		that the text directly after the cursor also matches a:pattern
"		(assuming something like '\<'.a:base.'\k\+') and appears in the
"		list.
"		Note: Matching is done via the searchpos() function, so the
"		'ignorecase' and 'smartcase' settings apply. Add |/\c| / |/\C|
"		to the regexp to set the case sensitivity.
"		Note: An empty pattern does not match at all, so take care of
"		passing a sensible default! '\V' will match every single
"		character individually; probably not what you want.
"		Note: for a:options.complete = 'b', matching is limited to
"		within single lines.
"   a:options	Dictionary with match configuration:
"   a:options.complete	    Specifies what is searched, like the 'complete'
"			    option. Supported options:
"			    - "." current buffer
"   a:options.backward_search	Flag whether to search backwards from the cursor
"				position.
"   a:options.extractor	    Funcref that extracts the matched text from the
"			    current buffer. Will be invoked with ([startLine,
"			    startCol], [endLine, endCol], matchObj) arguments
"			    with the cursor positioned at the start of the
"			    current match; must return string; can modify the
"			    initial matchObj.
"* RETURN VALUES:
"   a:matches
"*******************************************************************************
    let l:isBackward = (has_key(a:options, 'backward_search') ?
    \   a:options.backward_search :
    \   g:CompleteHelper_IsDefaultToBackwardSearch
    \)

    let l:save_view = winsaveview()
    let l:cursor = getpos('.')[1:2]

    let l:firstMatchPos = [0,0]
    while ! complete_check()
	let l:matchPos = searchpos( a:pattern, 'w' . (l:isBackward ? 'b' : '') )
	if l:matchPos == [0,0] || l:matchPos == l:firstMatchPos
	    " Stop when no matches or wrapped around to first match.
	    break
	endif
	if l:firstMatchPos == [0,0]
	    " Record first match position to detect wrap-around.
	    let l:firstMatchPos = l:matchPos
	endif

	let l:matchEndPos = searchpos( a:pattern, 'cen' )
	if a:isInCompletionWindow && ingo#pos#IsInside(l:cursor, l:matchPos, l:matchEndPos)
	    " Do not include a match around the cursor position; this would
	    " either just return the completion base, which Vim would not
	    " offer anyway, or the completion base and following text, which
	    " is unlikely to be desired, and not offered by the built-in
	    " completions, neither. By avoiding this match, we may shrink
	    " down the completion list to a single match, which would be
	    " inserted immediately without the user having to choose one.
	    continue
	endif

	" Initialize the match object and extract the match text.
	let l:matchObj = copy(a:matchTemplate)
	let l:matchText = (has_key(a:options, 'extractor') ? a:options.extractor(l:matchPos, l:matchEndPos, l:matchObj) : ingo#text#Get(l:matchPos, l:matchEndPos))

	if ! empty(l:matchText)
	    call add(a:matches, l:matchText)
	endif
    endwhile

    call winrestview(l:save_view)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
