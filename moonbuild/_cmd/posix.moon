import spawn from require 'posix'
import fork, execp, pipe, dup2, _exit, close from require 'posix.unistd'
import fdopen from require 'posix.stdio'
import wait from require 'posix.sys.wait'
import flatten, first from require 'moonbuild._common'
import remove from table

cmd = (...) ->
	code, ty = spawn flatten ...
	error "command #{first ...} #{ty} with code #{code}" if ty!='exited' or code!=0

cmdrst = (...) ->
	rd, wr = pipe!
	pid, err = fork!

	if pid == 0
		dup2 wr, 1
		close rd
		args = flatten ...
		c = remove args, 1
		execp c, args
		return _exit 1

	if pid == nil
		close rd
		close wr
		error "command #{first ...} failed to start: couldn't fork(): #{err}"

	close wr
	fd = fdopen rd, 'r'
	data = fd\read '*a'
	fd\close!
	close rd

	_, ty, code = wait pid
	error "command #{first ...} #{ty} with code #{code}" if ty!='exited' or code!=0
	data

sh = (cli) ->
	cmd 'sh', '-c', cli

{
	:cmd
	:cmdrst
	:sh
}
