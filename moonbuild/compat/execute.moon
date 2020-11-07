import execute from os

{
	execute: (cmd) ->
		a, b, c = execute cmd
		if (type a) == 'boolean'
			a, b, c
		else
			a==0 or nil, 'exit', a
}
