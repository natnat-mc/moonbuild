import match, gmatch, sub from string
import upper, lower from string

GLOB_PATT='^([^%%]*)%%([^%%]*)$'

patsubst = (str, pattern, replacement) ->
	return [patsubst s, pattern, replacement for s in *str] if (type str)=='table'

	if str==pattern
		return replacement

	prefix, suffix = match pattern, GLOB_PATT
	if not (prefix or suffix)
		return str

	reprefix, resuffix = match replacement, GLOB_PATT
	if not (reprefix or resuffix)
		if (#prefix==0 or (sub str, 1, #prefix)==prefix) and (#suffix==0 or (sub str, -#suffix)==suffix)
			return replacement
		else
			return str

	if #prefix==0 or (sub str, 1, #prefix)==prefix
		str = reprefix..(sub str, #prefix+1)
	if #suffix==0 or (sub str, -#suffix)==suffix
		str = (sub str, 1, -#suffix-1)..resuffix
	str

splitsp = (str) ->
	[elem for elem in gmatch str, '%S+']

{
	:patsubst
	:splitsp

	:upper, :lower
}
