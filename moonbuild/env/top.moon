initenv = require 'moonbuild.env.init'
Target = require 'moonbuild.core.Target'
Variable = require 'moonbuild.core.Variable'

(ctx, overrides) ->
	env, varlayer = initenv ctx

	rawset env, 'default', (target) ->
		ctx\adddefault target
		target

	rawset env, 'public', (e) ->
		clazz = ((getmetatable e) or {}).__class
		if clazz == Target
			e.public = true
		elseif clazz == Variable
			e.public = true
			override = overrides[e.name]
			if override
				override = nil if override == Variable.NIL
				e.value = override
				rawset varlayer, e.name, override
		else
			error "cannot set an object of type #{clazz and clazz.__name or type e} public"
		e

	rawset env, 'init', (fn) ->
		error "you can only add functions to init" unless (type fn) == 'function'
		ctx\addinit fn

	env, varlayer
