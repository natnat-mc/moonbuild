import first, filter, foreach, flatten, patsubst from require 'moonbuild._common'
import runwithcontext from require 'moonbuild.compat.ctx'
globalenv = require 'moonbuild.env.global'
import exists, parent, mkdirs, clearentry, disableentry, attributes from require 'moonbuild._fs'
import sort from table
import huge from math

local DepNode, FileTarget

nodepriority = (a, b) ->
	ta = type a.name
	tb = type b.name
	da = #a.deps
	db = #b.deps
	if ta=='string' and tb!='string'
		return true
	elseif ta!='string' and tb=='string'
		return false
	elseif a.priority > b.priority
		return true
	elseif a.priority < b.priority
		return false
	else
		return da < db

transclosure = (obj, prop) ->
	elems = {}
	i = 1
	set = {}
	imp = (e) ->
		for v in *e[prop]
			if not set[v]
				elems[i], i = v, i+1
				set[v] = i
				imp v
	imp obj
	elems

mtime = (path) ->
	attr = attributes path
	attr and attr.modification

class DepGraph
	new: (@ctx, names={}) =>
		@nodes = {}
		@env = globalenv @ctx
		for name in *names
			@addnode name

	addnode: (name) =>
		return if @nodes[name]
		elected = @resolvedeps name
		@nodes[name] = elected
		for dep in *(transclosure elected, 'deps')
			@nodes[dep.name] = dep
			dep.deps = nil
		elected.deps = nil

	resolvedeps: (name) =>
		do
			node = @nodes[name]
			return node, {} if node
		candidates = filter {@ctx.targets, FileTarget!}, (target) -> target\matches name
		nodes = foreach candidates, (candidate) -> a: {pcall -> DepNode @, candidate, name}
		resolved = foreach (filter nodes, (node) -> node.a[1]), (node) -> node.a[2]
		sort resolved, nodepriority
		resolved[1] or error "Cannot resolve target #{name}: #{#candidates} candidates, #{#resolved} resolved"

	buildablenodes: =>
		[v for k, v in pairs @nodes when v\canbuild! and not v.built]

class DepNode
	new: (@dag, target, @name) =>
		@priority = target.priority
		@buildfunctions = target.buildfunctions
		@mkdirs = target._mkdirs
		@sync = target._sync
		@type = target._type
		@outs = foreach target.outfiles, (name) -> patsubst @name, target.pattern, name
		@type = 'virtual' if #@outs == 0
		@built = false

		resolve = (name) -> @dag\resolvedeps patsubst @name, target.pattern, name
		after = flatten foreach target.needtargets, resolve
		deps = flatten foreach target.infiles, resolve
		if #target.depfunctions!=0
			ctx = setmetatable {},
				__index: (_, k) ->
					switch k
						when 'infile'
							f = first deps
							f and f.name
						when 'infiles'
							foreach deps, => @name
						when 'outfile'
							f = first @outs
							f and f.name
						when 'outfiles'
							foreach @outs, => @name
						when 'name'
							@name
						else
							error "No such field in TargetDepsContext: #{k}"
				__newindex: (k) =>
					error "Attempt to set field #{k} of TargetDepsContext"
			for depfn in *target.depfunctions
				deps = flatten deps, foreach (runwithcontext depfn, @dag.env, ctx), resolve
		@ins = foreach deps, (dep) -> dep.name
		@after = foreach after, (dep) -> dep.name
		@deps = flatten { deps, after }
		@built = true if #@deps == 0 and #@buildfunctions == 0

	canbuild: =>
		for node in *flatten { @ins, @after }
			if not @dag.nodes[node].built
				return false
		for file in *@ins
			if not exists file
				error "Node #{name} has ran all of its parents, but can't run since #{file} doesn't exist"
		return true

	build: (opts={}) =>
		force = opts.force or false
		quiet = opts.quiet or false

		return if @built
		return unless force or @shouldbuild!
		print "#{@type == 'virtual' and "Running" or "Building"} #{@name}" unless quiet or #@buildfunctions == 0
		@actuallybuild!


	shouldbuild: =>
		-- targets with no outputs / inputs and virtual targets *NEED* to be built
		return true if #@outs == 0 or #@ins == 0 or @type == 'virtual'

		-- check min mtime for outputs
		minout = huge
		for file in *@outs
			time = mtime file
			-- if an output file is missing, we *NEED* to build it
			return true if not time
			minout = time if time < minout

		-- check max mtime for inputs
		maxin = 0
		for file in *@ins
			time = mtime file
			maxin = time if time > maxin

		-- if any input file is more recent than any output file, we need to build
		maxin > minout

	actuallybuild: =>
		if @mkdirs
			mkdirs parent file for file in *@outs
		disableentry file for file in *@outs
		ctx = setmetatable {},
			__index: (_, k) ->
				switch k
					when 'infile' then @ins[1]
					when 'infiles' then @ins
					when 'outfile' then @outs[1]
					when 'outfiles' then @outs
					when 'name' then @name
					else error "No such field in TargetContext: #{k}"
			__newindex: (k) =>
				error "Attempt to set field #{k} of TargetContext"
		for fn in *@buildfunctions
			runwithcontext fn, @dag.env, ctx

	updatecache: =>
		clearentry file for file in *@outs

class FileTarget
	new: =>
		@priority = -huge
		@buildfunctions = {}
		@_mkdirs = false
		@_sync = false
		@_type = 'file'
		@needtargets = {}
		@infiles = {}
		@depfunctions = {}
		@outfiles = {'%'}
		@pattern = '%'

	matches: (name) =>
		exists name

DepGraph
