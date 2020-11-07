_ = require 'moonbuild._'

(ctx) ->
	varlayer = setmetatable {},
		__index: _G

	for name, var in pairs ctx.variables
		rawset varlayer, name, var.value

	env = setmetatable {},
		__index: varlayer
		__newindex: (k) => error "attempt to assign to global variable '#{k}', which is disabled in the global env"

	rawset env, '_', _
	rawset env, '_G', env
	rawset env, '_ENV', env

	env, varlayer
