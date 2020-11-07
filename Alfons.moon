tasks:
	build: =>
		sh "moon bin/moonbuild.moon -jy"
	release: =>
		error "no version provided" unless @v
		tasks.build!
		sh "rockbuild -m -t #{@v} upload"
