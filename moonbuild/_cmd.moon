import parseargs, escape from require 'moonbuild._cmd.common'

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

-- the library itself
setmetatable cmd, __call: => {'cmd', 'cmdrst', 'sh'}
