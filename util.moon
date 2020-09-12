import attributes, dir from require 'lfs'

import insert, concat, sort from table
unpack or=table.unpack

GLOB_PATT='^([^%%]*)%%([^%%]*)$'

-- min and max of table
max= (t) ->
	m=t[1]
	for i=2, #t
		v=t[i]
		m=v if v>m
	m
min= (t) ->
	m=t[1]
	for i=2, #t
		v=t[i]
		m=v if v<m
	m

-- simpler constructs
foreach= (tab, fn) ->
	[fn e for e in *tab]

first= (tab, fn) ->
	for e in *tab
		return e if fn e

exclude= (tab, ...) ->
	i=1
	while i<=#tab
		removed=false
		for j=1, select '#', ...
			if tab[i]==select j, ...
				table.remove tab, i
				removed=true
				break
		i+=1 unless removed
	tab

flatten= (tab) ->
	return {tab} if (type tab)!='table'
	out={}
	for e in *tab
		if (type e)=='table'
			insert out, v for v in *flatten e
		else
			insert out, e
	out

-- file functions
mtime= (f) ->
	a=attributes f
	a and a.modification
exists= (f) ->
	(attributes f)!=nil

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

-- file matcher
wildcard= (pattern) ->
	prefix, suffix=pattern\match '^(.*)%*%*(.*)$'
	if prefix
		fd=popen 'find', {(raw: '*'), '-name', "*#{suffix}"}
		found={}
		for line in fd\lines!
			insert found, line if (line\sub 1, #prefix)==prefix
		fd\close!
		return found

	directory, prefix, suffix=pattern\match '^(.*)/(.*)%*(.*)$'
	if directory
		found={}
		for file in dir directory
			if (file\sub 1, #prefix)==prefix and (file\sub -#suffix)==suffix
				insert found, "#{directory}/#{file}"
		return found

	prefix, suffix=pattern\match '^(.*)%*(.*)$'
	if prefix
		found={}
		for file in dir '.'
			if (file\sub 1, #prefix)==prefix and (file\sub -#suffix)==suffix
				insert found, file
		return found

	error "Invalid wildcard pattern: #{pattern}"

-- string pattern
patsubst= (str, pattern, replacement) ->
	return [patsubst s, pattern, replacement for s in *str] if (type str)=='table'
	prefix, suffix=pattern\match GLOB_PATT
	return str unless prefix
	reprefix, resuffix=replacement\match GLOB_PATT
	return replacement unless reprefix

	if (str\sub 1, #prefix)==prefix and (str\sub -#suffix)==suffix
		return reprefix..(str\sub #prefix+1, -#suffix-1)..resuffix
	str

splitsp= (str) ->
	[elem for elem in str\gmatch '%S+']

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

env= (key, def) ->
	(os.getenv key) or def

sortedpairs= (table, cmp) ->
	keys = [k for k in pairs table]
	sort keys, cmp
	coroutine.wrap ->
		for key in *keys
			coroutine.yield key, table[key]

{
	-- table functions
	:min, :max
	:foreach
	:first
	:insert, :unpack, :concat, :sort
	:exclude
	:flatten
	:sortedpairs

	-- file functions
	:wildcard
	:mtime, :exists

	-- command functions
	:run, :popen
	:calccdeps

	-- string functions
	:patsubst, :match, :isglob
	:env
	:splitsp
}
