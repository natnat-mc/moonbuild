# Moonbuild
Because `make` is painful to use, and build scripts are too slow. Moonbuild aims to be a good compromise.

You should probably use [`tup`](http://gittup.org/tup/) instead if you want a good build system.

## How does it work?
Basically like `make`, but in [Moonscript](https://moonscript.org) and with explicit ordering. See its `Build.moon` for examples (and you can compare it with the `Makefile`, both do the same thing).

## Why moonscript?
It's fast, based on lua, and it's easy to write DSLs with it, so the build instructions can be readable. Also, it's a full programming language, so there are no arbitrary restrictions.

## How do I install it?
- First, you'll need Lua 5.2 (untested) or 5.3 and [LuaRocks](https://luarocks.org)
- Then, you'll need `moonscript`, `argparse`, `luafilesystem` and `luastatic`, which you can get from `luarocks`
- Now, you can simply `make` Moonbuild, or build it with itself with `moon moonbuild.moon`
- You're now ready to install it, with `sudo make install` or `sudo ./moonbuild install`

## Now, how do I use it?
First, you'll need a `Build.moon`, `Buildfile.moon`, `Build` or `Buildfile` in the root of your project.
Then, you'll need a few `target`s, and ideally a `default target` (or the default target will be `all`). `public target`s will be listed by `moonbuild -l`.
To execute a command, you can use either `-cmd` or `#cmd` (the former will print it before executing it, the later won't).

### `[default] [public] target <name> [deps: <deps>] [in: <inputs>] [out: <outputs>] [from: <from>] [fn: <code>]`
Define a new target, and give it a list of depenancies, inputs, outputs and a function to run to build it.

`deps`, `in` and `out` can be either strings or tables. `from` acts like both `in` and `deps`. `name` must be a string and `code` must be a function, that will be given a table with the following fields:
- `name`: the name of the target
- `ins`: the table of inputs
- `infile`: the first input
- `outs`: the table of outputs
- `outfile`: the first output

If `name` is a glob, the target becomes a glob target.
Glob targets can be used with name that matches them (with a limit of one glob target per name, and no ordering is specified).
Glob targets will have their name substituted for their inputs, outputs and dependancies.

### `-cmd [<args>...]`
Prints and executes the command `cmd` with the given args. See `run` for how `args` works.

### `#cmd [<args>...]`
Executes without printing the command `cmd` with the given args. See `run` for how `args` works.

### `wildcard <wc>`
Returns a table with all the matching files. Valid wildcards contain either `**`, which can be expanded by any characters, including '/', or `*`, which cannot be expanded by `/`. Wildcards can only contain one `**` or `*`.

`wc` must be a string

### `exclude <list> [<exclusions>...]`
Removes all exclusions from the given list, and returns it.

`list` must be a table, and `exclusions` can be any type

### `patsubst <str> <patt> <subst>`
If the string matches `patt`, makes it match `subst` instead. If `str` is a table, it is recursively applied to all array values.

Patterns are in the format `[prefix]%[suffix]`, with the `%` representing any sequence of characters, including `/`.

`str`, `pat` and `subst` must be strings

### `foreach <table> <code>`
Applies `code` to every element of `table`, and returns the resulting table.

`table` must be a table, and `code` a function.

### `min|max <table>`
Returns either the min or max value of the given table.

`table` must be a table

### `first <table> <code>`
Returns the first value of the table that verifies the given condition.

`table` must be a table, and `code` a function

### `flatten <table>`
Flattens a table so that it has exactly one dimension.

`table` can be anything

### `insert|unpack|concat`
The functions, imported from the `table` library.

### `mtime <file>`
Returns the modification time of `file`, or `nil` if it doesn't exist.

`file` must be a string

### `exists <file>`
Returns `true` if the file exists, `false` otherwise.

`file` must be a string

### `run <cmd> [<args> [print: <print>] [error: <error>]]`
Runs the given command with the given arguments. If `print` is truthy, prints the command before executing it, and if `error` is truthy, crashes if the command fails. Returns a boolean which is true if the command ended with success, and a number which is the return code.

`cmd` must be a string, `args` must be a table, which can contain either strings or other tables. `raw: <val>` is a special kind of argument that will not be escaped. `print` and `error` can be anything, but booleans or nil are recommended

### `popen <cmd> [<args> [print: <print>]]`
Same as `run`, but returns a `io.popen` handle.

## License
MIT
