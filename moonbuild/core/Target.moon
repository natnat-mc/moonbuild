import flatten, includes, patget from require 'moonbuild._common'
import insert from table

class Target
	new: (@ctx, @name, opts={}) =>
		@name = flatten @name if (type @name) != 'string'
		@pattern = opts.pattern or ((type @name) == 'string' and @name or '%')
		@priority = opts.priority or 0
		error "pattern must be a string" unless (type @pattern) == 'string'
		error "priority must be an int" unless (type @priority) == 'number' and @priority%1 == 0

		@outfiles = {}
		@infiles = {}
		@needtargets = {}
		@depfunctions = {}
		@buildfunctions = {}
		@_mkdirs = false
		@_sync = false
		@_type = 'normal'
		@public = false

	matches: (name) =>
		if @name==name
			return true
		if (includes @name, name) and patget name, @pattern
			return true
		return false

	produces: (...) =>
		n = #@outfiles+1
		for obj in *flatten ...
			@outfiles[n], n = obj, n+1

	depends: (...) =>
		if (type ...) == 'function'
			insert @depfunctions, (...)
		else
			n = #@infiles+1
			for obj in *flatten ...
				@infiles[n], n = obj, n+1

	after: (...) =>
		n = #@needtargets+1
		for tgt in *flatten ...
			@needtargets[n], n = tgt, n+1

	fn: (fn) =>
		insert @buildfunctions, fn

	sync: =>
		@_sync = true

	mkdirs: =>
		@_mkdirs = true
