import escape from require 'moonbuild._cmd.common'
import flatten from require 'moonbuild._common'
import execute from require 'moonbuild.compat.execute'
import popen from io
import concat from table

cmdline = (...) ->
	concat [escape arg for arg in *flatten ...], ' '

cmd = (...) ->
	ok, ret, code = execute cmdline ...
	error "command #{first ...} exited with #{code} (#{ret})" unless ok

cmdrst = (...) ->
	fd, err = popen cmdline ...
	error err unless fd
	data = fd\read '*a'
	fd\close!
	data

sh = (cli) ->
	ok, ret, code = execute cli
	error "command '#{cli}' exited with #{code} (#{ret})" unless ok

{
	:cmd
	:cmdrst
	:sh
}
