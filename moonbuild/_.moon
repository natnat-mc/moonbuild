import gmatch, match, gsub from string
import insert, remove, concat, sub, sort from table

_fs = require 'moonbuild._fs'
_cmd = require 'moonbuild._cmd'
_util = require 'moonbuild._util'
_common = require 'moonbuild._common'

_ = {}

for k, lib in pairs {:_fs, :_cmd, :_util, :_common}
	_[k] = lib
	for n in *lib!
		_[n] = lib[n]
_
