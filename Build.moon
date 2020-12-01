public var 'MOONC', 'moonc'
public var 'AMALG', 'amalg.lua'
public var 'RM', 'rm', '-f', '--'
public var 'LUA', 'lua5.3'

var 'LIB_SRC', _.wildcard 'moonbuild/**.moon'
var 'BIN_SRC', _.wildcard 'bin/*.moon'

var 'LIB_LUA', _.patsubst LIB_SRC, '%.moon', '%.lua'
var 'BIN_LUA', _.patsubst BIN_SRC, '%.moon', '%.lua'
var 'BIN', _.patsubst BIN_LUA, 'bin/%.lua', 'out/%'
var 'LIB', 'out/moonbuild.lua'

var 'MODULES', _.foreach (_.patsubst LIB_LUA, '%.lua', '%'), => @gsub '/', '.'

with public default target 'all'
	\after 'bin'
	\after 'lib'

with public target 'install'
	\after 'install-bin'
	\after 'install-lib'

with public target 'install-bin'
	\depends BIN
	\produces _.patsubst BIN, 'out/%', '/usr/local/bin/%'
	\fn => _.cmd 'sudo', 'cp', @infile, @out
	\sync!

with public target 'install-lib'
	\depends LIB
	\produces "/usr/local/share/lua/#{LUA\gsub 'lua', ''}/moonbuild.lua"
	\fn => _.cmd 'sudo', 'cp', @infile, @out
	\sync!

with public target 'clean'
	\fn => _.cmd RM, LIB_LUA
	\fn => _.cmd RM, BIN_LUA

with public target 'mrproper'
	\after 'clean'
	\fn => _.cmd RM, BIN, LIB

with public target 'bin'
	\depends BIN

with public target 'lib'
	\depends LIB_LUA, LIB

with target BIN, pattern: 'out/%'
	\depends 'bin/%.lua'
	\produces 'out/%'
	\mkdirs!
	\fn =>
		_.writefile @out, "#!/usr/bin/env #{LUA}\n#{_.readfile @infile}"
		_.cmd 'chmod', '+x', @out

with target LIB
	\depends 'moonbuild/init.lua'
	\depends LIB_LUA
	\produces '%'
	\fn => _.cmd AMALG, '-o', @out, '-s', @infile, _.exclude MODULES, 'moonbuild.init'

with target {LIB_LUA, BIN_LUA}, pattern: '%.lua'
	\depends '%.moon'
	\produces '%.lua'
	\fn => _.moonc @infile, @out
