import loadfile from require 'moonscript.base'
Context = require 'moonbuild.context'
DepGraph = require 'moonbuild.core.DAG'
Executor = require 'moonbuild.core.executor'
_ = require 'moonbuild._'
import insert from table

moonbuild = (...) ->
	-- build argument table
	opts = {}
	for i=1, select '#', ...
		arg = select i, ...
		if (type arg) == 'string'
			insert opts, arg
		elseif (type arg) == 'table'
			for k, v in pairs arg
				opts[k] = v if (type k) != 'number'
			for i, v in ipairs arg
				insert opts, v
		else
			error "Invalid argument type #{type arg} for moonbuild"

	-- resolve arguments
	buildfile = opts.buildfile or opts.b or 'Build.moon'
	opts.buildfile = buildfile
	parallel = opts.parallel or opts.j or 1
	parallel = true if parallel == 'y'
	opts.parallel = parallel
	quiet = opts.quiet or opts.q or false
	opts.quiet = quiet
	force = opts.force or opts.f or false
	opts.force = force
	verbose = opts.verbose or opts.v or false
	opts.verbose = verbose

	-- set verbosity level
	_.verbose verbose

	-- create context and DAG
	ctx = Context!
	ctx\load (loadfile buildfile), opts
	_.verbose "Loaded buildfile"
	ctx\init!
	_.verbose "Initialized buildfile"
	targets = #opts==0 and ctx.defaulttargets or opts
	dag = DepGraph ctx, targets
	_.verbose "Created dependancy graph"

	-- and build
	nparallel = parallel == true and Executor\getmaxparallel! or parallel
	_.verbose "Building with #{nparallel} max parallel process#{nparallel>1 and "es" or ""}"
	executor = Executor dag, nparallel
	executor\execute opts
	_.verbose "Finished"

table = {
	:moonbuild, :_
	:Context, :DepGraph, :Executor
}

setmetatable table,
	__call: (...) => moonbuild ...
	__index: (name) => require "moonbuild.#{name}"
