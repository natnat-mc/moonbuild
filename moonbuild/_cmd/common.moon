import gsub, sub, match from string
import concat from table

specialchars =
	'\"': '\\\"'
	'\\': '\\\\'
	'\'': '\\\''
	'\n': '\\n'
	'\r': '\\r'
	'\t': '\\t'

replacespecialchar = (c) -> specialchars[c] or c

escape = (arg) ->
	return arg if match arg, "^[a-zA-Z0-9_.-]+$"
	'"'..(gsub arg, "([\"\\\n\r\t])", replacespecialchar)..'"'

parseargs = (argstr) ->
	state = 'normal'
	current, ci = {}, 1
	args, ai = {}, 1
	c = nil
	i = 0
	running = true

	add = ->
		current[ci], ci = c, ci+1
	push = ->
		args[ai], ai, current, ci = (concat current), ai+1, {}, 1 if ci!=1
	addv = (v) ->
		current[ci], ci = v, ci+1
	fail = (msg) ->
		error "failed to parse: #{msg} in state #{state} at pos #{i}", 2
	finish = ->
		running = false
	EOF = ''

	while running
		i += 1
		c = sub argstr, i, i

		switch state
			when 'normal'
				switch c
					when '\"'
						state = 'doublequote'
					when '\''
						state = 'singlequote'
					when ' '
						push!
					when '\n'
						push!
					when '\t'
						push!
					when '\\'
						state = 'backslashnormal'
					when EOF
						push!
						finish!
					else
						add!

			when 'doublequote'
				switch c
					when '\"'
						state = 'normal'
					when '\\'
						state = 'backslashdoublequote'
					when EOF
						fail "unexpected EOF"
					else
						add!

			when 'singlequote'
				switch c
					when '\''
						state = 'normal'
					when EOF
						fail "unexpected EOF"
					else
						add!

			when 'backslashnormal'
				switch c
					when '\n'
						state = 'normal'
					when EOF
						fail "unexpected EOF"
					else
						add!
						state = 'normal'

			when 'backslashdoublequote'
				switch c
					when '$'
						add!
						state = 'doublequote'
					when '`'
						add!
						state = 'doublequote'
					when '\"'
						add!
						state = 'doublequote'
					when '\\'
						add!
						state = 'doublequote'
					when '\n'
						state = 'doublequote'
					when EOF
						fail "unexpected EOF"
					else
						addv '\\'
						add!
						state = 'doublequote'

	args

{
	:escape
	:parseargs
}
