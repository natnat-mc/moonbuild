public var AMALG: 'amalg.lua'
public var RM: 'rm', '-f', '--'
public var LUA: 'lua5.3'

var LIB_SRC: _.wildcard 'moonbuild/**.moon'
var BIN_SRC: _.wildcard 'bin/*.moon'

var LIB_LUA: _.patsubst LIB_SRC, '%.moon', '%.lua'
var BIN_LUA: _.patsubst BIN_SRC, '%.moon', '%.lua'
var BIN: _.patsubst BIN_LUA, 'bin/%.lua', 'out/%'
var LIB: 'out/moonbuild.lua'

var MODULES: _.foreach (_.patsubst LIB_LUA, '%.lua', '%'), => @gsub '/', '.'

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

with pipeline! -- lib
	\sources LIB_SRC
	\step 'compile-lib'
		pattern: {'%.moon', '%.lua'}
		fn: => _.moonc @infile, @out
	\step 'lib'
		output: LIB
		fn: => _.cmd AMALG, '-o', @out, '-s', 'moonbuild/init.lua', _.exclude MODULES, 'moonbuild.init'

with pipeline! -- bin
	\sources BIN_SRC
	\step 'compile-bin'
		pattern: {'%.moon', '%.lua'}
		fn: => _.moonc @infile, @out
	\step 'bin'
		pattern: {'bin/%.lua', 'out/%'}
		mkdirs: true
		fn: =>
			_.writefile @out, "#!/usr/bin/env #{LUA}\n#{_.readfile @infile}"
			_.cmd 'chmod', '+x', @out
