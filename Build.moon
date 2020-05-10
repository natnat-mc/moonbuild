SOURCES_MOON = wildcard '*.moon'
exclude SOURCES_MOON, 'Build.moon'
OUT_LUA      = patsubst SOURCES_MOON, '%.moon', '%.lua'
BINARY       = 'moonbuild'
MAIN         = "#{BINARY}.moon"
MAIN_LUA     = patsubst MAIN, '%.moon', '%.lua'
OUT_C        = patsubst MAIN, '%.moon', '%.lua.c'
PREFIX       = env 'PREFIX', '/usr/local'
INSTALL_LOC  = "#{PREFIX}/bin"

default public target 'all', deps: BINARY

public target 'install', from: BINARY, out: INSTALL_LOC, fn: =>
	-install @infile, @outfile

public target 'clean', fn: =>
	-rm '-f', OUT_LUA
	-rm '-f', OUT_C

public target 'mrproper', deps: 'clean', fn: =>
	-rm '-f', BINARY

public target 'info', fn: =>
	#echo "Moonscript sources:", SOURCES_MOON
	#echo "Compiled lua:", OUT_LUA
	#echo "Binary:", BINARY

target BINARY, out: {BINARY, OUT_C}, from: OUT_LUA, fn: =>
	-luastatic MAIN_LUA, OUT_LUA, '-I/usr/include/lua5.3', '-llua5.3'

foreach OUT_LUA, (file) ->
	source=patsubst file, '%.lua', '%.moon'
	target file, in: source, out: file, fn: =>
		-moonc @infile
