import parseargs, escape, cmdline from require 'moonbuild._cmd.common'
import verbose from require 'moonbuild._common'

ok, cmd, backend = false, nil, nil
unless ok
	ok, cmd = pcall -> require 'moonbuild._cmd.posix'
	backend = 'posix'
unless ok
	ok, cmd = pcall -> require 'moonbuild._cmd.lua'
	backend = 'lua'
error "unable to load any cmd library, tried luaposix and posix commands" unless ok

-- from the backend
cmd = {k, v for k, v in pairs cmd}
cmd.backend = backend

-- common cmd function
cmd.parseargs = parseargs
cmd.escape = escape

-- make verbose verisons of _.cmd, _.cmdrst and _.sh
for f in *({'cmd', 'cmdrst'})
	orig = cmd[f]
	cmd[f] = (...) ->
		verbose "[#{f}] #{cmdline ...}"
		orig ...
_sh = cmd.sh
cmd.sh = (cli) ->
	verbose "[sh] #{cli}"
	_sh cli

-- derived cmd functions
_cmd = cmd.cmd
_cmdrst = cmd.cmdrst
cmd.cmdline = (cmdline) -> _cmd parseargs cmdline
cmd.cmdlinerst = (cmdline) -> _cmdrst parseargs cmdline

-- the library itself
setmetatable cmd, __call: => {'cmd', 'cmdrst', 'cmdline', 'cmdlinerst', 'sh'}
