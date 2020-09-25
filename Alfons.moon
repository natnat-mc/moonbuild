tasks:
	build: =>
		sh "moon bin/moonbuild.moon compile"
	test: =>
		sh "busted"
	install: =>
		sh "moon bin/moonbuild.moon install"
	release: =>
		error "no version provided" unless @v
		tasks.build!
		sh "rockbuild -m -t #{@v} upload"
