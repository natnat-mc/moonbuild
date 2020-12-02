Target = require 'moonbuild.core.Target'
Variable = require 'moonbuild.core.Variable'
Pipeline = require 'moonbuild.core.Pipeline'
_ = require 'moonbuild._'
import flatten from _

(ctx) ->
	varlayer = setmetatable {},
		__index: _G

	for name, var in pairs ctx.variables
		rawset varlayer, name, var.value

	env = setmetatable {},
		__index: varlayer
		__newindex: (k) => error "attempt to assign to global variable '#{k}', use the function 'var' instead"

	rawset env, '_', _
	rawset env, '_G', env
	rawset env, '_ENV', env

	rawset env, 'var', (...) ->
		var = Variable ...
		ctx\addvar var
		rawset varlayer, var.name, var.value
		var

	rawset env, 'target', (name, opts) ->
		target = Target ctx, name, opts
		ctx\addtarget target
		target

	rawset env, 'pipeline', ->
		Pipeline ctx

	env, varlayer
