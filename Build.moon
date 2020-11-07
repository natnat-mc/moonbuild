public var 'MOONC', 'moonc'
public var 'AMALG', 'amalg.lua'
public var 'RM', 'rm', '-f', '--'
public var 'LUA', 'lua5.3'

var 'LIB_SRC', _.wildcard 'moonbuild/**.moon'
var 'BIN_SRC', _.wildcard 'bin/*.moon'

var 'LIB_LUA', _.patsubst LIB_SRC, '%.moon', '%.lua'
var 'BIN_LUA', _.patsubst BIN_SRC, '%.moon', '%.lua'
var 'BIN', _.patsubst BIN_LUA, 'bin/%.lua', 'out/%'

var 'MODULES', _.foreach (_.patsubst LIB_LUA, '%.lua', '%'), => @gsub '/', '.'

with public default target 'all'
	\after 'bin'
	\after 'lib'

with public target 'install'
	\depends 'out/moonbuild'
	\produces '/usr/local/bin/moonbuild'
	\fn => _.cmd 'sudo', 'cp', @infile, @outfile

with public target 'clean'
	\fn => _.cmd RM, LIB_LUA
	\fn => _.cmd RM, BIN_LUA

with public target 'mrproper'
	\after 'clean'
	\fn => _.cmd RM, BIN

with public target 'bin'
	\depends BIN

with public target 'lib'
	\depends LIB_LUA

with target BIN, pattern: 'out/%'
	\depends 'bin/%.lua'
	\depends LIB_LUA
	\produces 'out/%'
	\mkdirs!
	\fn =>
		_.cmd AMALG, '-o', @outfile, '-s', @infile, MODULES
		_.writefile @outfile, "#!/usr/bin/env #{LUA}\n#{_.readfile @outfile}"
		_.cmd 'chmod', '+x', @outfile

with target {LIB_LUA, BIN_LUA}, pattern: '%.lua'
	\depends '%.moon'
	\produces '%.lua'
	\fn => _.moonc @infile, @outfile
