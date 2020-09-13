SOURCES_MOON = wildcard 'moonbuild/**.moon'
BINARY       = 'bin/moonbuild.moon'
OUT_LUA      = patsubst SOURCES_MOON, '%.moon', '%.lua'
BINARY_LUA   = patsubst BINARY, '%.moon', '%.lua'
OUT_AMALG    = 'moonbuild.lua'

public target 'clean', fn: =>
	-rm '-f', OUT_LUA

public target 'info', fn: =>
	#echo "Moonscript sources:", SOURCES_MOON
	#echo "Compiled lua:", OUT_LUA

default target 'compile', from: OUT_AMALG

target OUT_AMALG, from: {BINARY_LUA, OUT_LUA}, out: OUT_AMALG, fn: =>
	modules = foreach (patsubst OUT_LUA, '%.lua', '%'), => @gsub '/', '.'
	-Command 'amalg.lua', '-o', @outfile, '-s', 'bin/moonbuild.lua', modules

target '%.lua', in: '%.moon', out: '%.lua', fn: =>
	-moonc @infile
