import flatten from require 'moonbuild._common'
class Variable
	@NIL: ->

	new: (@name, ...) =>
		@public = false
		if (select '#', ...) !=1 or (type ...) == 'table'
			@value = flatten ...
		else
			@value = ...

