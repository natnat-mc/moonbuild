import match, gmatch, sub from string
import upper, lower from string

GLOB_PATT='^([^%%]*)%%([^%%]*)$'

patsubst = (str, pattern, replacement) ->
	return [patsubst s, pattern, replacement for s in *str] if (type str)=='table'
	prefix, suffix = match pattern, GLOB_PATT
	return str unless prefix
	reprefix, resuffix = match replacement, GLOB_PATT
	return replacement unless reprefix

	if (sub str, 1, #prefix)==prefix and (sub str, -#suffix)==suffix
		return reprefix..(sub str, #prefix+1, -#suffix-1)..resuffix
	str

splitsp = (str) ->
	[elem for elem in gmatch str, '%S+']

{
	:patsubst
	:splitsp

	:upper, :lower
}
