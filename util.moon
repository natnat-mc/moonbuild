import wildcard, exists, isdir, mtime from require 'fsutil'
import foreach, first, flatten, exclude, sortedpairs, min, max from require 'tableutil'
import patsubst, splitsp from require 'stringutil'

import insert, concat, sort, pairs from require 'tableutil'
import upper, lower from require 'stringutil'

GLOB_PATT='^([^%%]*)%%([^%%]*)$'

-- command functions
escapecmdpart= (p) ->
	if (type p)=='table'
		return p.raw if p.raw
		return concat [escapecmdpart part for part in *p], ' '
	return p if p\match '^[a-zA-Z0-9_./-]+$'
	'"'..p\gsub('\\', '\\\\')\gsub('"', '\\"')..'"'
escapecmd= (c, args={}) ->
	c=escapecmdpart c
	for a in *flatten args
		c..=' '..escapecmdpart a if a
	c
run= (c, args, params={}) ->
	escaped=escapecmd c, args
	print escaped if params.print
	ret, _, code=os.execute escaped
	ret, code=ret==0, ret if (type ret)=='number'
	error "#{c} failed with code #{code}" if params.error and not ret
	ret, code
popen= (c, args, mode='r', params={}) ->
	escaped=escapecmd c, args
	print escaped if params.print
	io.popen escaped, mode

calccdeps= (infile, includesys=false) ->
	data=(popen 'cc', {includesys and '-M' or '-MM', infile})\read '*a'
	rawdeps=data\gsub('\\\n', '')\match ':(.+)'
	[dep for dep in rawdeps\gmatch '%S+' when dep!=infile]

findclib= (name, mode='all') ->
	args={name}
	insert args, '--cflags' if mode=='all' or mode=='cc'
	insert args, '--libs' if mode=='all' or mode=='ld'
	[arg for arg in (popen 'pkg-config', args)\read('*a')\gmatch '%S+']

-- glob match
match= (str, glob) ->
	prefix, suffix=glob\match GLOB_PATT
	return str==glob unless prefix
	return str\sub #prefix+1, -#suffix-1 if (str\sub 1, #prefix)==prefix and (str\sub -#suffix)==suffix
	false

-- is a valid glob
isglob= (glob) ->
	return if glob\match GLOB_PATT
		true
	else
		false

-- getenv
env= (key, def) ->
	(os.getenv key) or def

{
	-- table function
	:min, :max
	:foreach
	:first
	:exclude
	:flatten
	:sortedpairs

	:insert, :remove, :concat, :sort
	:unpack

	-- file functions
	:wildcard
	:mtime
	:exists, :isdir

	-- command functions
	:run, :popen
	:calccdeps, :findclib

	-- string functions
	:patsubst
	:splitsp

	:upper, :lower

	-- glob functions
	:match, :isglob

	-- env functions
	:env
}
