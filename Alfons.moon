tasks:
	bootstrap: => sh "moon bin/moonbuild.moon -jy"
	bootstrapinstall: => sh "moon bin/moonbuild.moon install -jy"

	release: =>
		error "no version provided" unless @v
		tasks.build!
		sh "rockbuild -m -t #{@v} upload"

	build: => (require 'moonbuild') j: true
	install: => (require 'moonbuild') 'install', j: true
	clean: => (require 'moonbuild') 'clean'
	mrproper: => (require 'moonbuild') 'mrproper'
