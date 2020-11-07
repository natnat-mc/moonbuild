tasks:
	build: =>
		load 'moonbuild'
		tasks.moonbuild j: true
	release: =>
		error "no version provided" unless @v
		tasks.build!
		sh "rockbuild -m -t #{@v} upload"
