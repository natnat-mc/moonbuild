import insert, remove, concat, sort from table
unpack or= table.unpack

sortedpairs = (table, cmp) ->
	keys = [k for k in pairs table]
	sort keys, cmp
	coroutine.wrap ->
		for key in *keys
			coroutine.yield key, table[key]

min = (table, cmp=(a, b) -> a<b) ->
	val = table[1]
	for i=2, #table
		elem = table[i]
		if cmp elem, val
			val = elem
	val

max = (table, cmp=(a, b) -> a<b) ->
	val = table[1]
	for i=2, #table
		elem = table[i]
		if not cmp elem, val
			val = elem
	val

foreach = (tab, fn) ->
	[fn e for e in *tab]

first = (tab, fn) ->
	for e in *tab
		return e if fn e

exclude = (tab, ...) ->
	i=1
	while i<=#tab
		removed=false
		for j=1, select '#', ...
			if tab[i]==select j, ...
				remove tab, i
				removed = true
				break
		i += 1 unless removed
	tab

flatten = (tab) ->
	return {tab} if (type tab)!='table'
	out = {}
	for e in *tab
		if (type e)=='table'
			insert out, v for v in *flatten e
		else
			insert out, e
	out

{
	:min, :max
	:foreach
	:first
	:exclude
	:flatten
	:sortedpairs

	:insert, :remove, :concat, :sort
	:unpack
}
