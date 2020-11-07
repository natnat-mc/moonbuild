pcall = require 'moonbuild.compat.pcall'

runwithcontext = if setfenv
	(fn, ctx, ...) ->
		env = getfenv fn
		setfenv fn, ctx
		local data, ndata, ok
		acc = (succ, ...) ->
			ok = succ
			if succ
				data = {...}
				ndata = select '#', ...
			else
				data = ...
		acc pcall fn, ...
		setfenv fn, env
		if ok
			unpack data, 1, ndata
		else
			error data

else
	import dump from string
	(fn, ctx, ...) ->
		code = dump fn, false
		fn = load code, 'runwithcontext', 'b', ctx
		fn ...

{ :runwithcontext }
