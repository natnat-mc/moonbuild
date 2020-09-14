import attributes, dir from require 'lfs'
unpack or= table.unpack

FROZEN = ->

makecached = (fn) ->
	cache = {}

	invalidate = (val) ->
		cache[val] = nil

	freeze = (val) ->
		cache[val] = FROZEN

	reset = ->
		cache = {}

	get = (val) ->
		cached = cache[val]
		if cached!=FROZEN and cached!=nil
			return unpack cached
		ret = {fn val}
		if cached!=FROZEN
			cache[val] = ret
		unpack ret

	setmetatable { :get, :invalidate, :freeze, :reset },
		__call: (val) => get val

{
	attributes: makecached attributes
	dir: makecached dir
}
