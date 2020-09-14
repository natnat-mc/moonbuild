SOURCES_MOON = wildcard 'moonbuild/**.moon'
BINARY       = 'bin/moonbuild.moon'
OUT_LUA      = patsubst SOURCES_MOON, '%.moon', '%.lua'
BINARY_LUA   = patsubst BINARY, '%.moon', '%.lua'
OUT_AMALG    = 'moonbuild.lua'

public target 'clean', fn: =>
	-rm '-f', OUT_LUA, BINARY_LUA

public target 'info', fn: =>
	#echo "Moonscript sources:", SOURCES_MOON
	#echo "Compiled lua:", OUT_LUA

public target 'compile', deps: OUT_AMALG

public target 'install', from: OUT_AMALG, out: '/usr/local/bin/moonbuild', fn: =>
	dfd, err = io.open @outfile, 'w'
	error err unless dfd
	ifd, err = io.open @infile, 'r'
	error err unless ifd
	dfd\write '#!/usr/bin/env lua5.3\n'
	for line in ifd\lines!
		dfd\write line, '\n'
	ifd\close!
	dfd\close!
	-chmod '+x', @outfile
	#echo "Installed at:", @outfile

default target OUT_AMALG, from: {BINARY_LUA, OUT_LUA}, out: OUT_AMALG, fn: =>
	modules = foreach (patsubst OUT_LUA, '%.lua', '%'), => @gsub '/', '.'
	-Command 'amalg.lua', '-o', @outfile, '-s', 'bin/moonbuild.lua', modules

target '%.lua', in: '%.moon', out: '%.lua', fn: =>
	-moonc @infile
