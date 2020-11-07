import runwithcontext from require 'moonbuild.compat.ctx'
topenv = require 'moonbuild.env.top'
initenv = require 'moonbuild.env.init'
import includes from require 'moonbuild._common'
import insert from table

class Context
	new: =>
		@targets = {}
		@defaulttargets = {}
		@variables = {}
		@inits = {}

	addvar: (var) =>
		@variables[var.name] = var

	addinit: (fn) =>
		insert @inits, fn

	addtarget: (target) =>
		insert @targets, target

	resetexecuted: =>
		@executedtargets = {}

	adddefault: (target) =>
		error "not a target of the current context: #{target}" unless includes @targets, target
		error "not a named target" unless (type target.name) == 'string'
		insert @defaulttargets, target.name

	load: (code, overrides) =>
		runwithcontext code, (topenv @, overrides)

	init: =>
		if @inits[1]
			env = (initenv @)
			for init in *@inits
				runwithcontext code, env
