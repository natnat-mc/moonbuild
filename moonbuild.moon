#!/usr/bin/env moon

argparse=require 'argparse'

require 'moonscript'
import loadfile from require 'moonscript.base'
import truncate_traceback, rewrite_traceback from require 'moonscript.errors'
import trim from require 'moonscript.util'

util=require 'util'
import exists, mtime, run, min, max, first, flatten, match, patsubst, sortedpairs from util

import insert, concat from table

parser=argparse 'moonbuild'
parser\argument('targets', "Targets to run")\args '*'
parser\flag '-a --noskip', "Always run targets"
parser\flag '-l --list', "List available targets"
parser\flag '-d --deps', "List targets and their dependancies"
args=parser\parse!

-- util functions
loadwithscope= (file, scope) ->
	fn, err=loadfile file
	error err or "failed to load code" unless fn
	dumped, err=string.dump fn
	error err or "failed to dump function" unless dumped
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
	skip={}

	@find: (name) =>
		target=all[name]
		return target if target
		for glob, tgt in pairs all
			return tgt if match name, glob
		nil

	@list: =>
		{target, {dep, @find dep for dep in *target.deps} for name, target in pairs all}

	@build: (name, upper) =>
		target=(@find name) or error "No such target: #{name}"
		target\build name, upper

	__tostring: =>
		"Target #{@name} (#{concat @deps, ', '})"

	new: (@name, @outs={}, @ins={}, @deps={}, @fn= =>) =>
		@skip=false
		error "Duplicate build name #{@name}" if all[@name]
		all[@name]=@

	build: (name, upper={}) =>
		return if skip[name]
		error "Cycle detected on #{@name}" if upper[@]
		upper = setmetatable {[@]: true}, __index: upper
		if @name!=name
			@@build (patsubst name, @name, dep), upper for dep in *@deps
		else
			@@build dep, upper for dep in *@deps
		return unless @shouldbuild name

		ins=@ins
		outs=@outs
		if @name!=name
			ins=[patsubst name, @name, elem for elem in *@ins]
			outs=[patsubst name, @name, elem for elem in *@outs]
			print "Building #{@name} as #{name}"
		else
			print "Building #{name}"
		ok, err=pcall ->
			@.fn
				ins: ins
				outs: outs
				infile: ins[1]
				outfile: outs[1]
				name: name
		error "Can't build #{@name}: lua error\n#{err}" unless ok
		for f in *outs
			error "Can't build #{@name}: output file #{f} not created" unless exists f
		skip[name]=true

	shouldbuild: (name) =>
		return true if args.noskip
		return true if #@ins==0 or #@outs==0

		ins=if @name!=name
			[patsubst name, @name, elem for elem in *@ins]
		else
			@ins
		itimes=[mtime f for f in *ins]
		for i=1, #@ins
			error "Can't build #{@name}: missing inputs" unless itimes[i]

		outs=if @name!=name
			[patsubst name, @name, elem for elem in *@outs]
		else
			@outs
		otimes=[mtime f for f in *outs]
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
error "Failed to load build function" unless buildfn
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

if args.deps
	io.write "Targets:\n"
	for target, deps in sortedpairs BuildObject\list!, (a, b) -> a.name<b.name
		io.write "\t#{target.name} "
		if #target.ins==0
			if #target.outs==0
				io.write "[no in/out]"
			else
				io.write "[spontaneous generation]"
		else
			if #target.outs==0
				io.write "[consumer]"
			else
				io.write "(#{concat target.ins, ', '} -> #{concat target.outs, ', '})"
		io.write "\n"
		for name, dep in sortedpairs deps
			io.write "\t\t#{name} (#{dep.name})\n"
	os.exit 0

if #args.targets==0
	BuildObject\build defaulttarget
for target in *args.targets
	BuildObject\build target
