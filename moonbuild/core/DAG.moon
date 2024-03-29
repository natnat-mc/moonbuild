import first, filter, foreach, flatten, patsubst, includes from require 'moonbuild._common'
import runwithcontext from require 'moonbuild.compat.ctx'
globalenv = require 'moonbuild.env.global'
import exists, parent, mkdirs, clearentry, disableentry, attributes from require 'moonbuild._fs'
import sort, insert, remove from table
import huge from math

local DepNode, FileTarget

nodepriority = (a, b) ->
	ta = type a.name
	tb = type b.name
	da = #a.deps
	db = #b.deps
	sa = a.sync
	sb = b.sync
	if ta=='string' and tb!='string'
		return true
	elseif ta!='string' and tb=='string'
		return false
	elseif a.priority > b.priority
		return true
	elseif a.priority < b.priority
		return false
	elseif sa and not sb
		return false
	elseif sb and not sa
		return true
	else
		return da < db

transclosure = (obj, prop) ->
	elems = {}
	i = 1
	set = {}
	imp = (e) ->
		return unless e[prop]
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
		elected = @topresolvedeps name
		@nodes[name] = elected
		for dep in *(transclosure elected, 'deps')
			@nodes[dep.name] = dep
			dep.deps = nil
		elected.deps = nil

	topresolvedeps: (name) =>
		errors = {}
		ok, rst = pcall -> @resolvedeps name, nil, errors
		if ok
			rst
		else
			msg = {"Failed to resolve target \'#{name}\'\n"}
			for e in *errors
				if e.err\match '^moonbuild'
					e.err = e.err\match ': (.+)$'
			for i=#errors, 1, -1
				e = errors[i]
				insert msg, "#{string.rep '| ', e.level - 1}+-[#{e.name}] level #{e.level}: #{e.err}"
			insert msg, ''
			error table.concat msg, '\n'

	resolvedeps: (name, level=1, errors={}) =>
		do
			node = @nodes[name]
			if node
				print "deps(#{name}) = #{node.name or '[noname]'}"
				return node, {}
		candidates = filter {@ctx.targets, FileTarget!}, (target) -> target\matches name
		nodes = foreach candidates, (candidate) -> a: {pcall -> DepNode @, candidate, name, level, errors}
		resolved = foreach (filter nodes, (node) -> node.a[1]), (node) -> node.a[2]
		sort resolved, nodepriority
		unless resolved[1]
			err = "Cannot resolve target #{name}: #{#candidates} candidates, #{#resolved} resolved"
			table.insert errors, {:name, :level, :err}
			error err
		resolved[1]

	buildablenodes: =>
		[v for k, v in pairs @nodes when v\canbuild! and not v.built]

	reset: =>
		n.built = false for k, n in pairs @nodes

	resetchildren: (names) =>
		done = {}
		stack = [v for v in *names]
		while #stack != 0
			name = remove stack
			continue if done[name]
			done[name] = true
			node = @nodes[name]
			node.built = false
			insert stack, n for n in *(node\children!)

class DepNode
	new: (@dag, target, @name, @level, errors) =>
		@priority = target.priority
		@buildfunctions = target.buildfunctions
		@mkdirs = target._mkdirs
		@sync = target._sync
		@type = target._type
		@outs = foreach target.outfiles, (name) -> patsubst @name, target.pattern, name
		@type = 'virtual' if #@outs == 0
		@built = false

		resolve = (name) -> @dag\resolvedeps (patsubst @name, target.pattern, name), level + 1, errors
		after = flatten foreach target.needtargets, resolve
		deps = flatten foreach target.infiles, resolve
		if #target.depfunctions!=0
			ctx = setmetatable {},
				__index: (_, k) ->
					switch k
						when 'infile', 'in'
							f = first deps
							f and f.name
						when 'infiles'
							foreach deps, => @name
						when 'outfile', 'out'
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

	children: =>
		[k for k, n in pairs @dag.nodes when (includes n.ins, @name) or (includes n.after, @name)]

	canbuild: =>
		for node in *flatten { @ins, @after }
			if not @dag.nodes[node].built
				return false
		for file in *@ins
			if not exists file
				error "Node #{@name} has ran all of its parents, but can't run since #{file} doesn't exist. Did you mean to use after instead of depends?"
		return true

	build: (opts={}) =>
		force = opts.force or false
		quiet = opts.quiet or false

		return false if @built or #@buildfunctions == 0
		return false unless force or @shouldbuild!
		print "#{@type == 'virtual' and "Running" or "Building"} #{@name} [level #{@level}]" unless quiet
		@actuallybuild!
		true


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
					when 'infile', 'in' then @ins[1]
					when 'infiles' then @ins
					when 'outfile', 'out' then @outs[1]
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
