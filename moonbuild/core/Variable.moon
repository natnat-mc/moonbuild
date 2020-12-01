import flatten from require 'moonbuild._common'
class Variable
	@NIL: ->

	new: (@name, ...) =>
		@public = false
		if (type @name) == 'table'
			error "not a valid var table: #{next @name}" unless (type next @name) == 'string'
			error "more than one var at once: #{next @name}, #{next @name, (next @name)}" if next @name, (next @name)
			name = next @name
			@name, param = name, @name
			val = param[name]
			if (select '#', ...) !=0 or (type val) == 'table'
				@value = flatten val, ...
			else
				@value = val
		elseif (select '#', ...) !=1 or (type ...) == 'table'
			@value = flatten ...
		else
			@value = ...

