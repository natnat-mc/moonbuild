-- load everything we need
import loadfile from require 'moonscript.base'
Context = require 'moonbuild.context'
DepGraph = require 'moonbuild.core.DAG'

tasks:
	moonbuild: =>
		args = {
			nparallel: @parallel or @j
			quiet: @quiet or @q
			buildfile: @buildfile or @b
			force: @force or @f
		}
		ctx = Context!
		ctx\load (loadfile args.buildfile or 'Build.moon'), @
		ctx\init!
		dag = DepGraph ctx, #@ == 0 and ctx.defaulttargets or @
		executor = do
			Executor = do
				ok, Executor = pcall -> require 'moonbuild.core.multiprocessexecutor'
				ok and Executor or require 'moonbuild.core.singleprocessexecutor'
			args.nparallel = Executor\getmaxparallel! if args.nparallel == true
			Executor dag, args.nparallel
		executor\execute args
