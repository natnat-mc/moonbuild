import dir, attributes from require 'moonbuild.fscache'

import gmatch, match, gsub, sub from string
import insert, remove, concat from table

normalizepath = (file) ->
	parts = [part for part in gmatch file, '[^/]+']
	absolute = (sub file, 1, 1)=='/'
	for i=1, #parts
		if parts[i]=='.'
			remove parts, i
			i -= 1
			continue
		if parts[i]=='..' and i!=1
			remove parts, i
			remove parts, i-1
			i -= 2
			continue
	(absolute and '/' or '') .. concat parts, '/'

ls = (d) ->
	[f for f in *dir normalizepath d when f!='.' and f!='..']

lswithpath = (d) ->
	return ls '.' if d==''
	[d..'/'..f for f in *dir normalizepath d when f!='.' and f!='..']

exists = (f) ->
	(attributes normalizepath f) != nil

isdir = (f) ->
	a = attributes normalizepath f
	a and a.mode == 'directory' or false

mtime = (f) ->
	a = attributes normalizepath f
	a and a.modification

matchglob = (str, glob) ->
	patt = '^'..(gsub (gsub glob, '%*%*', '.*'), '%*', '[^/]*')..'$'
	rst = if (type str)=='table'
		results, i = {}, 1
		for s in *str
			rst = (match s, patt) and s
			results[i], i = rst, i+1 if rst
		results
	else
		(match str, patt) and str
	rst

wildcard = (glob) ->
	parts = [part for part in gmatch glob, '[^/]+']
	absolute = (sub glob, 1, 1)=='/'

	for i, part in ipairs parts
		prevpath = (absolute and '/' or '') .. concat parts, '/', 1, i-1
		currpath = prevpath .. '/' .. part

		if match part, '%*%*.*%*%*'
			error "Two '**' in the same path component in a wildcard"

		if match part, '%*%*'
			prefix = match currpath, '^(.*)%*%*'
			suffix = (match part, '%*%*(.*)$') .. (i==#parts and '' or ('/'..concat parts, '/', i+1, #parts))
			files = lswithpath prevpath

			results = {}
			for file in *files
				if matchglob file, currpath
					if i==#parts
						insert results, file
					elseif isdir file
						for result in *wildcard file .. '/' .. concat parts, '/', i+1, #parts
							insert results, result
				if (matchglob file, prefix..'**') and isdir file
					for result in *wildcard file .. '/**' .. suffix
						insert results, result
			return results

		if match part, '%*'
			files = lswithpath prevpath

			if i==#parts
				return matchglob files, glob

			results = {}
			for file in *files
				if (matchglob file, currpath) and isdir file
					for result in *wildcard file .. '/' .. concat parts, '/', i+1, #parts
						insert results, result
			return results

	if exists glob
		return {glob}
	else
		return {}

parentdir = (file) ->
	normalizepath file..'/..'

freezecache = (file) ->
	dir.freeze file
	dir.freeze parentdir file
	attributes.invalidate file

invalidatecache = (file) ->
	dir.invalidate file
	dir.invalidate parentdir file
	attributes.invalidate file

clearcache = ->
	dir.clear!
	attributes.clear!

{
	:wildcard
	:exists, :isdir
	:mtime
	:normalizepath, :parentdir
	:freezecache, :invalidatecache, :clearcache
}
