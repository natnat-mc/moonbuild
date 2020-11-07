import to_lua from require 'moonscript.base'
import parseargs, cmdrst from require 'moonbuild._cmd'
import gmatch, match, gsub from string
import open from io

util = {}

_pkgconfig = (mode, ...) ->
	parseargs cmdrst 'pkg-config', "--#{mode}", ...
pkgconfig = setmetatable {}, __index: (mode) => (...) -> _pkgconfig mode, ...

_cdeps = (cc, cflags, path) ->
	raw = cmdrst cc, cflags, '-M', path
	rawlist = gsub (match raw, ':(.+)'), '\\\n', ' '
	[v for v in gmatch rawlist, '%S+']
cdeps = setmetatable {},
	__index: (cc) => (cflags, path) -> _cdeps cc, cflags, path
	__call: (cflags, path) => _cdeps 'cc', cflags, path

readfile = (filename) ->
	fd, err = open filename, 'rb'
	error err unless fd
	data, err = fd\read '*a'
	error err unless data
	fd\close!
	data

writefile = (filename, data) ->
	fd, err = open filename, 'wb'
	error err unless fd
	ok, err = fd\write data
	error err unless ok
	fd\close!
	nil

moonc = (infile, outfile) ->
	code, err = to_lua readfile infile
	error "Failed to compile #{@infile}: #{err}" unless code
	writefile outfile, code

util.pkgconfig = pkgconfig
util.cdeps = cdeps
util.readfile = readfile
util.writefile = writefile
util.moonc = moonc

setmetatable util, __call: => [k for k in pairs util]
