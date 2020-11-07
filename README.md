# moonbuild
**Now in v2 - complete rework from v1**

Because `make` is painful to use, and build scripts are too slow. Moonbuild aims to be a good compromise.  
You should probably use [http://gittup.org/tup/](tup) instead if you want a good build system.

## How does it work?
`moonbuild` reads a build file, usually `Build.moon` that is written in a Moonscript DSL to define its targets and variables.  
It then builds a DAG for the dependancies of the targets you tell it to build.  
Then, it tries building every target in the graph while respecting dependancies, possibly on multiple processes.

Essentially, it works the same way as `make`, just with a different language, you can compare the `Build.moon` and `Makefile` in this repo to see for yourself.

## Why Moonscript?
Because it's fast, based on lua, and making DSLs with it is relatively easy.  
It's also a language I like a lot, so I might have been biased when choosing it.

## Installing
It is available on luarocks with `luarocks install moonbuild`.  
It is also recommended to install `luaposix` if you can, as it speeds it up a lot, or `luafilesystem` in case it isn't available.

## Building from source
You will need `argparse` and `moonscript` installed from luarocks, and `luaposix` or `luafilesystem` are recommended.

### Bootstrapping
You can build moonbuild with itself: `moon bin/moonbuild.moon -qjy`.  
This will leave the binary ready to be used as `out/moonbuild`.

### Using make
You can also build moonbuild with make: `make`.
This will leave the binary ready to be used as `out/moonbuild`.

## Docs
TODO
