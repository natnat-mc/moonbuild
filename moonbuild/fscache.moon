import attributes, dir from require 'lfs'
unpack or= table.unpack

FROZEN = ->

makecached = (fn) ->
	cache = {}

	invalidate = (val) ->
		cache[val] = nil

	freeze = (val) ->
		cache[val] = FROZEN

	clear = ->
		cache = {}

	get = (val) ->
		if cache == FROZEN
			return fn val
		cached = cache[val]
		if cached!=FROZEN and cached!=nil
			return unpack cached
		ret = {fn val}
		if cached!=FROZEN
			cache[val] = ret
		unpack ret

	enable = ->
		cache = {} if cache==FROZEN

	disable = ->
		cache = FROZEN

	setmetatable { :get, :invalidate, :freeze, :clear, :enable, :disable },
		__call: (val) => get val

cached = {
	attributes: makecached attributes
	dir: makecached (file) -> [k for k in dir file]
}

enable = ->
	fn\enable! for _, fn in cached

disable = ->
	fn\disable! for _, fn in cached

clear = ->
	fn\clear! for _, fn in cached

setmetatable { :enable, :disable, :clear }, __index: cached
