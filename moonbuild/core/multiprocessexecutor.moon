SingleProcessExecutor = require 'moonbuild.core.singleprocessexecutor'
import fork, _exit from require 'posix.unistd'
import wait from require 'posix.sys.wait'
import open, stderr from io
import match from string

class Executor
	@getmaxparallel: =>
		fd = open '/proc/cpuinfo', 'r'
		return 1 unless fd
		ncpu = 0
		for line in fd\lines!
			ncpu += 1 if match line, '^processor%s*:'
		fd\close!
		ncpu == 0 and 1 or ncpu

	new: (@dag, @nparallel) =>
		@processes = {}
		@nprocesses = 0
		@building = {}
		@nbuilt = 0

	execute: (opts) =>
		if @nparallel == 1
			return (SingleProcessExecutor @dag, 1)\execute opts

		block = @dag\buildablenodes!
		while #block != 0
			for node in *block
				@addprocess node, opts
				if @nprocesses == @nparallel
					@waitprocess!
			block = [node for node in *@dag\buildablenodes! when not @building[node]]
			while #block == 0 and @nprocesses != 0
				@waitprocess!
				block = [node for node in *@dag\buildablenodes! when not @building[node]]

		while @nprocesses !=0
			@waitprocess!

		for name, node in pairs @dag.nodes
			error "Node #{name} wasn't built" unless node.built

		unless opts.quiet
			if @nbuilt == 0
				print "Nothing to be done"
			else
				print "Built #{@nbuilt} targets"

	addprocess: (node, opts) =>
		if node.sync
			while @nprocesses != 0
				@waitprocess!
			node\build opts
			node.built = true
			node\updatecache!
			return

		pid = fork!
		error "Failed to fork" unless pid
		if pid!=0
			@processes[pid] = node
			@nprocesses += 1
			@building[node] = true
		else
			ok, status = pcall -> node\build opts
			if ok
				_exit status and 0 or 2
				_exit 0
			else
				stderr\write status
				_exit 1

	waitprocess: =>
		pid, ty, status = wait!
		error "Failed to wait" unless pid
		error "Failed to build #{@processes[pid].name}" if ty != 'exited' or status != 0 and status != 2
		@processes[pid].built = true
		@processes[pid]\updatecache!
		@processes[pid] = nil
		@nprocesses -= 1
		@nbuilt += 1 if status == 0
