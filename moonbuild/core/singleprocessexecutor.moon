class Executor
	@getmaxparallel: => 1

	new: (@dag, @nparallel) =>

	execute: (opts) =>
		nbuilt = 0

		block = @dag\buildablenodes!
		while #block != 0
			for node in *block
				nbuilt +=1 if node\build opts
				node\updatecache!
				node.built = true
			block = @dag\buildablenodes!

		for name, node in pairs @dag.nodes
			error "Node #{name} wasn't built" unless node.built

		unless opts.quiet
			if nbuilt == 0
				print "Nothing to be done"
			else
				print "Built #{nbuilt} targets"
