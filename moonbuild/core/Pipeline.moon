Target = require 'moonbuild.core.Target'
_ = require 'moonbuild._'
import flatten, patsubst from _

class Pipeline
	new: (@ctx) =>
		@lastsources = {}

	sources: (...) =>
		@lastsources = flatten @lastsources, ...
	source: (src) =>
		@lastsources = flatten @lastsources, src

	step: (name, params) =>
		public = true
		public, params = false, name if (type name) == 'table'

		tgttype = if params.pattern
			error "pattern must be a table with the same format as patsubst" unless (type params.pattern) == 'table' and (type params.pattern[1]) == 'string' and (type params.pattern[2]) == 'string'
			'pattern'
		elseif params.output or params.out
			error "output must be a string" unless (type params.output or params.out) == 'string'
			'single'
		else
			error "invalid step type for pipeline: must be pattern or single (out/output)"

		tgtouts = switch tgttype
			when 'pattern' then patsubst @lastsources, params.pattern[1], params.pattern[2]
			when 'single' then params.output or params.out

		tgtpatt = switch tgttype
			when 'pattern' then params.pattern[2]
			when 'single' then nil

		tgtins = switch tgttype
			when 'pattern' then params.pattern[1]
			when 'single' then @lastsources

		tgtprod = switch tgttype
			when 'pattern' then params.pattern[2]
			when 'single' then '%'

		tgt = with Target @ctx, tgtouts, pattern: tgtpatt
			\depends tgtins
			\produces tgtprod
			\fn params.fn or error "pipeline steps need a fn"
		tgt\mkdirs! if params.mkdirs
		tgt\sync! if params.sync
		@ctx\addtarget tgt

		if public
			@ctx\addtarget with Target @ctx, name
				\depends tgtouts
				.public = true

		@lastsources = tgtouts
