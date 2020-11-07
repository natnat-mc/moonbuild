import remove, concat from table
import gmatch, match, gsub, sub from string

-- load backend
ok, fs, backend = false, nil, nil
unless ok
	ok, fs = pcall -> require 'moonbuild._fs.posix'
	backend = 'posix'
unless ok
	ok, fs = pcall -> require 'moonbuild._fs.lfs'
	backend = 'lfs'
unless ok
	ok, fs = pcall -> require 'moonbuild._fs.cmd'
	backend = 'cmd'
error "unable to load any fs library, tried luaposix, luafilesystem and posix commands" unless ok

-- caching mechanism
DISABLED = ( -> DISABLED )
NIL = ( -> NIL )

cacheenabled = true
caches = {}

clearcache = ->
	v.clearcache! for k, v in pairs caches
clearentry = (entry) ->
	v.clearentry entry for k, v in pairs caches
disableentry = (entry) ->
	v.disableentry entry for k, v in pairs caches
disablecache = ->
	cacheenabled = false
enablecache = ->
	cacheenabled = true

withcache = (fn) ->
	opts = {}
	opts.cache = {}
	opts.clearcache = ->
		opts.cache = {}
	opts.clearentry = (entry) ->
		opts.cache[entry] = nil
	opts.disableentry = (entry) ->
		opts.cache[entry] = DISABLED
	caches[fn] = opts

	setmetatable opts,
		__call: (arg) =>
			return fn arg unless cacheenabled
			cached = opts.cache[arg]
			return fn arg if cached == DISABLED
			return nil if cached == NIL
			return cached if cached != nil
			cached = fn arg
			opts.cache[arg] = cached
			opts.cache[arg] = NIL if cached == nil
			return cached

fs = {
	dir: withcache fs.dir
	attributes: withcache fs.attributes
	mkdir: fs.mkdir
}
import attributes, dir, mkdir from fs

-- actual functions
normalizepath = (file) ->
	parts = [part for part in gmatch file, '[^/]+']
	absolute = (sub file, 1, 1)=='/'
	i = 1
	while i<=#parts
		if parts[i]=='.'
			remove parts, i
			continue
		if parts[i]=='..' and i!=1 and parts[i-1]!='..'
			remove parts, i
			remove parts, i-1
			i -= 1
			continue
		i += 1
	if #parts==0
		absolute and '/' or '.'
	else
		(absolute and '/' or '') .. concat parts, '/'

ls = (d) ->
	[f for f in *dir normalizepath d when f!='.' and f!='..']

lswithpath = (d) ->
	return ls '.' if d==''
	[d..'/'..f for f in *dir normalizepath d when f!='.' and f!='..']

matchglob = (str, glob) ->
	glob = gsub glob, '[%[%]%%+.?-]', => '%'..@
	patt = '^'..(gsub glob, '%*%*?', => @=='**' and '.*' or '[^/]*')..'$'
	rst = if (type str)=='table'
		results, i = {}, 1
		for s in *str
			rst = (match s, patt) and s
			results[i], i = rst, i+1 if rst
		results
	else
		(match str, patt) and str
	rst

exists = (f) ->
	(attributes normalizepath f) != nil

isdir = (f) ->
	((attributes normalizepath f) or {}).mode == 'directory'

wildcard = (glob) ->
	parts = [part for part in gmatch glob, '[^/]+']
	absolute = (sub glob, 1, 1)=='/'

	for i, part in ipairs parts
		prevpath = (absolute and '/' or '') .. concat parts, '/', 1, i-1
		currpath = (i==1 and '' or (prevpath .. '/')) .. part

		if match part, '%*%*.*%*%*'
			error "Two '**' in the same path component in a wildcard"

		if match part, '%*%*'
			prefix = match currpath, '^(.*)%*%*'
			suffix = (match part, '%*%*(.*)$') .. (i==#parts and '' or ('/'..concat parts, '/', i+1, #parts))
			return {} unless exists prevpath
			files = lswithpath prevpath

			results, ri = {}, 1
			for file in *files
				if matchglob file, currpath
					if i==#parts
						results[ri], ri = file, ri+1
					elseif isdir file
						for result in *wildcard file .. '/' .. concat parts, '/', i+1, #parts
							results[ri], ri = result, ri+1
				if (matchglob file, prefix..'**') and isdir file
					for result in *wildcard file .. '/**' .. suffix
						results[ri], ri = result, ri+1
			return results

		if match part, '%*'
			return {} unless exists prevpath
			files = lswithpath prevpath

			if i==#parts
				return matchglob files, glob

			results, ri = {}, 1
			for file in *files
				if (matchglob file, currpath) and isdir file
					for result in *wildcard file .. '/' .. concat parts, '/', i+1, #parts
						results[ri], ri = result, ri+1
			return results

	if exists glob
		return {glob}
	else
		return {}

parent = (file) ->
	normalizepath file..'/..'

actualmkdir = mkdir
mkdir = (dir) ->
	actualmkdir dir
	clearentry parent dir

mkdirs = (dir) ->
	return if isdir dir
	error "Can't mkdirs #{dir}: file exists" if exists dir
	mkdirs parent dir
	mkdir dir

-- from the backend
fs = {k, withcache fn for k, fn in pairs fs}

-- own functions
fs.normalizepath = normalizepath
fs.ls = ls
fs.lswithpath = lswithpath
fs.matchglob = matchglob
fs.exists = exists
fs.isdir = isdir
fs.wildcard = wildcard
fs.parent = parent
fs.mkdir = mkdir
fs.mkdirs = mkdirs

-- cache and backend
fs.clearcache = clearcache
fs.clearentry = clearentry
fs.disableentry = disableentry
fs.disablecache = disablecache
fs.enablecache = enablecache
fs.backend = backend

-- the library itself
setmetatable fs, __call: => {'dir', 'ls', 'normalizepath', 'exists', 'isdir', 'wildcard', 'mkdir', 'mkdirs'}
