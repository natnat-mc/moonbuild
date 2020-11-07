import dir, attributes, mkdir from require 'lfs'

{
	dir: (path) ->
		[v for v in dir path]

	attributes: attributes

	mkdir: (path) ->
		ok, err = mkdir path
		error "Failed to mkdir #{path}: #{err}" unless ok
}
