-- load everything we need
import loadfile from require 'moonscript.base'
Context = require 'moonbuild.context'
Variable = require 'moonbuild.core.Variable'
DepGraph = require 'moonbuild.core.DAG'
import parseargs from require 'moonbuild._cmd.common'
import sort, concat from table
import exit from os

-- parse the arguments
argparse = require 'argparse'
parser = with argparse "moonbuild", "A build system in moonscript"
	\option '-b --buildfile', "Build file to use", 'Build.moon'
	\option '-j --parallel', "Sets the number of parallel tasks, 'y' to run as many as we have cores", '1'
	\flag '-l --list', "List the targets", false
	\flag '-V --list-variables', "List the variables", false
	\flag '-q --quiet', "Don't print targets as they are being built", false
	\flag '-f --force', "Always rebuild every target", false
	\flag '-v --verbose', "Be verbose", false
	(\option '-u --unset', "Unsets a variable")\count '*'
	(\option '-s --set', "Sets a variable")\args(2)\count '*'
	(\option '-S --set-list', "Sets a variable to a list")\args(2)\count '*'
	(\argument 'targets', "Targets to build")\args '*'
	\add_complete!

args = parser\parse!

overrides = {}
for unset in *args.unset
	overrides[unset] = Variable.NIL
for set in *args.set
	overrides[set[1]] = set[2]
for set in *args.set_list
	overrides[set[1]] = parseargs set[2]

args.parallel = args.parallel == 'y' and 'y' or ((tonumber args.parallel) or error "Invalid argument for -j: #{args.parallel}")
error "Invalid argument for -j: #{args.parallel}" if args.parallel != 'y' and (args.parallel<1 or args.parallel%1 != 0)
print "Parsed CLI args" if args.verbose

-- load the buildfile
ctx = Context!
ctx\load (loadfile args.buildfile), overrides
print "Loaded buildfile" if args.verbose

-- handle -l and -V
if args.list
	print "Public targets"
	targets, n = {}, 1
	for t in *ctx.targets
		if t.public
			targets[n], n = t.name, n+1
	sort targets
	print concat targets, ", "
	print!
	exit 0 unless args.list_variables
if args.list_variables
	print "Public variables"
	vars, n = {}, 1
	for k, v in pairs ctx.variables
		if v.public
			vars[n], n = k, n+1
	sort vars
	print concat vars, ", "
	print!
	exit 0

-- initialize the buildfile further
ctx\init!
print "Initialized buildfile" if args.verbose

-- create the DAG
targets = #args.targets==0 and ctx.defaulttargets or args.targets
dag = DepGraph ctx, targets
print "Created dependancy graph" if args.verbose

-- execute the build
if args.parallel==1
	Executor = require 'moonbuild.core.singleprocessexecutor'
	executor = Executor dag, args.parallel
	executor\execute args
else
	ok, Executor = pcall -> require 'moonbuild.core.multiprocessexecutor'
	Executor = require 'moonbuild.core.singleprocessexecutor' unless ok
	nparallel = args.parallel == 'y' and Executor\getmaxparallel! or args.parallel
	print "Building with #{nparallel} max parallel process#{nparallel>1 and "es" or ""}" if args.verbose
	executor = Executor dag, nparallel
	executor\execute args
print "Finished" if args.verbose
