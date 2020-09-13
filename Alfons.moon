tasks:
	build: =>
		sh "moon bin/moonbuild.moon compile-lua"
	release: =>
		error "no version provided" unless @v
		tasks.build!
		sh "rockbuild -m -t #{@v} upload"
