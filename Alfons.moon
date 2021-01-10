require 'moonscript'
moonbuild = require 'moonbuild'

tasks:
	release: =>
		error "no version provided" unless @v
		tasks.build!
		sh "rockbuild -m -t #{@v} upload"

	watch: => watch {'.'}, {'.git'}, 'live', (glob '*.moon'), pcall -> moonbuild j: true
	build: => moonbuild j: true
	install: => moonbuild 'install', j: true
	clean: => moonbuild 'clean'
	mrproper: => moonbuild 'mrproper'
