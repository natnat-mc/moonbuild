class Executor
	@getmaxparallel: => 1

	new: (@dag, @nparallel) =>

	execute: (opts) =>
		block = @dag\buildablenodes!
		while #block != 0
			for node in *block
				node\build opts
				node\updatecache!
				node.built = true
			block = @dag\buildablenodes!

		for name, node in pairs @dag.nodes
			error "Node #{name} wasn't built" unless node.built
