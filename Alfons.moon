tasks:
	build: =>
		sh "moon bin/moonbuild.moon compile"
	install: =>
		sh "moon bin/moonbuild.moon install"
	release: =>
		error "no version provided" unless @v
		tasks.build!
		sh "rockbuild -m -t #{@v} upload"
