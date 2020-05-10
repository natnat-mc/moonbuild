#!/usr/bin/env moon

argparse=require 'argparse'

require 'moonscript'
import loadfile from require 'moonscript.base'
import truncate_traceback, rewrite_traceback from require 'moonscript.errors'
import trim from require 'moonscript.util'

util=require 'util'
import exists, mtime, run, min, max, first, flatten from util

import insert, concat from table

parser=argparse 'moonbuild'
parser\argument('targets', "Targets to run")\args '*'
parser\flag '-a --noskip', "Always run targets"
parser\flag '-l --list', "List available targets"
args=parser\parse!

-- util functions
loadwithscope= (file, scope) ->
	fn=loadfile file
	dumped=string.dump fn
	load dumped, file, 'b', scope
pcall= (fn, ...) ->
	rewrite=(err) ->
		trace=debug.traceback '', 2
		trunc=truncate_traceback trim trace
		rewrite_traceback trunc, err
	xpcall fn, rewrite, ...

-- command object
-- represents a command that can be called
class Command
	new: (@cmd, ...) =>
		@args={...}

	__unm: => @run error: true, print: true
	__len: => @run error: true
	__tostring: => @cmd

	run: (params) => run @cmd, @args, params
	@run: (...) => -@ ...

-- build object
-- represents a target
class BuildObject
	all={}

	@build: (name) =>
		target=all[name] or error "No such target: #{name}"
		target\build!

	new: (@name, @outs={}, @ins={}, @deps={}, @fn= =>) =>
		@skip=false
		error "Duplicate build name #{@name}" if all[@name]
		all[@name]=@

	build: =>
		return if @skip
		error "Can't build #{@name}: cyclic dependancy" if @cycle
		@cycle=true
		for depname in *@deps
			dep=all[depname] or error "Can't build #{@name}: missing dependancy #{depname}"
			dep\build!
		return unless @shouldbuild!

		print "Building #{@name}"
		ok, err=pcall ->
			@.fn ins: @ins, outs: @outs, infile: @ins[1], outfile: @outs[1], name: @name
		error "Can't build #{@name}: lua error\n#{err}" unless ok
		for f in *@outs
			error "Can't build #{@name}: output file #{f} not created" unless exists f
		@skip=true

	shouldbuild: =>
		return true if args.noskip
		return true if #@ins==0 or #@outs==0

		itimes=[mtime f for f in *@ins]
		for i=1, #@ins
			error "Can't build #{@name}: missing inputs" unless itimes[i]

		otimes=[mtime f for f in *@outs]
		for i=1, #@outs
			return true if not otimes[i]

		(max itimes)>(min otimes)

error "Need Lua >=5.2" if setfenv

targets={}
defaulttarget='all'

buildscope=
	default: (target) ->
		defaulttarget=target.name
		target
	public: (target) ->
		insert targets, target.name
		target
	target: (name, params) ->
		tout=flatten params.out
		tin=flatten params.in
		tdeps=flatten params.deps
		for f in *flatten params.from
			insert tin, f
			insert tdeps, f
		BuildObject name, tout, tin, tdeps, params.fn
buildscope[k]=fn for k, fn in pairs util

setmetatable buildscope,
	__index: (k) =>
		global=rawget _G, k
		return global if global
		(...) -> Command k, ...

file=first {'Build.moon', 'Buildfile.moon', 'Build', 'Buildfile'}, exists
error "No Build.moon or Buildfile found" unless file
buildfn=loadwithscope file, buildscope
ok, err=pcall buildfn
unless ok
	if err
		io.stderr\write err, '\n'
	else
		io.stderr\write "Unknown error\n"
	os.exit 1

if args.list
	io.write "Available targets:\n"
	io.write "\t#{concat targets, ', '}\n"
	os.exit 0

if #args.targets==0
	BuildObject\build defaulttarget
for target in *args.targets
	BuildObject\build target
