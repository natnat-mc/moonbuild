import sort, concat from table
import huge from math
import match, sub from string

common = {}

flatten = (list, ...) ->
	return flatten {list, ...} if (select '#', ...)!=0
	t = type list
	switch t
		when 'nil'
			{}
		when 'string'
			{list}
		when 'number'
			{tostring list}
		when 'boolean'
			{list}
		when 'table'
			keys = [k for k in pairs list]
			sort keys
			elements, i = {}, 1
			for k in *keys
				if (type k)=='number'
					for e in *(flatten list[k])
						elements[i], i = e, i+1
				else
					return {list}
			setmetatable elements, __tostring: => concat @, ' '
		else
			error "can't flatten elements of type #{t}"

first = (list, ...) ->
	t = type list
	switch t
		when 'nil'
			if (select '#', ...)==0
				nil
			else
				first ...
		when 'string'
			list
		when 'number'
			tostring list
		when 'boolean'
			list
		when 'table'
			min = huge
			for k in pairs list
				if (type k) == 'number'
					min = k if k < min
				else
					return list
			first list[min]
		else
			error "can't find first of type #{t}"

foreach = (list, fn) ->
	[fn v for v in *flatten list]

filter = (list, fn) ->
	[v for v in *flatten list when fn v]

includes = (list, v) ->
	return true if list==v
	if (type list) == 'table'
		for k, e in pairs list
			if (type k) == 'number'
				return true if includes e, v
	if (type list) == 'number'
		return (tostring list) == (tostring v)
	false

patget = (s, pat) ->
	prefix, suffix = match pat, '^(.*)%%(.*)$'
	return s==pat and s or nil unless prefix
	if (sub s, 1, #prefix)==prefix and (suffix == '' or (sub s, -#suffix)==suffix)
		sub s, #prefix+1, -#suffix-1
	else
		nil

patset = (s, rep) ->
	prefix, suffix = match rep, '^(.*)%%(.*)$'
	if prefix
		prefix..s..suffix
	else
		rep

patsubst = (s, pat, rep) ->
	prefix, suffix = match pat, '^(.*)%%(.*)$'
	rprefix, rsuffix = match rep, '^(.*)%%(.*)$'

	t = type s
	f = false
	if t=='nil'
		return nil
	if t=='number'
		t = 'string'
		s = tostring s
	if t=='string'
		t = 'table'
		s = {s}
		f = true
	if t!='table'
		error "can't substitute patterns on type #{t}"

	r, i = {}, 1
	for s in *flatten s
		if not prefix
			if s==pat
				if rprefix
					r[i], i = rprefix..s..rsuffix, i+1
				else
					r[i], i = rep, i+1
		elseif (sub s, 1, #prefix)==prefix and (suffix == '' or (sub s, -#suffix)==suffix)
			if rprefix
				r[i], i = rprefix..(sub s, #prefix+1, -#suffix-1)..rsuffix, i+1
			else
				r[i], i = rep, i+1

	f and r[1] or r

exclude = (list, ...) ->
	exclusions = flatten ...
	[v for v in *flatten list when not includes exclusions, v]

min = (list) ->
	m = list[1]
	for i=2, #list
		e = list[i]
		m = e if e<m
	m

max = (list) ->
	m = list[1]
	for i=2, #list
		e = list[i]
		m = e if e>m
	m

minmax = (list) ->
	m = list[1]
	M = list[1]
	for i=2, #list
		e = list[i]
		m = e if e<m
		M = e if e>M
	m, M

_verbose = false
verbose = (arg) ->
	if arg == nil
		_verbose
	elseif (type arg) == 'function'
		arg! if _verbose
	elseif (type arg) == 'boolean'
		_verbose = arg
	elseif (type arg) == 'string'
		print arg if _verbose
	else
		error "_.verbose takes either no argument, a boolean, a function or a string"

common.flatten = flatten
common.first = first
common.foreach = foreach
common.filter = filter
common.includes = includes
common.patget = patget
common.patset = patset
common.patsubst = patsubst
common.exclude = exclude
common.min = min
common.max = max
common.minmax = minmax
common.verbose = verbose

setmetatable common, __call: => [k for k in pairs common]
