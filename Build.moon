SOURCES_MOON = flatten {'bin/moonbuild.moon', wildcard 'moonbuild/**.moon'}
OUT_LUA      = patsubst SOURCES_MOON, '%.moon', '%.lua'

public target 'clean', fn: =>
	-rm '-f', OUT_LUA

public target 'info', fn: =>
	#echo "Moonscript sources:", SOURCES_MOON
	#echo "Compiled lua:", OUT_LUA

default target 'compile-lua', from: OUT_LUA

target '%.lua', in: '%.moon', out: '%.lua', fn: =>
	-moonc @infile
