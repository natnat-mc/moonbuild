-- project name
var 'NAME', 'raytrace'

-- tools to use
public var 'CPP', 'g++'
public var 'LD', 'g++'
public var 'MOC', 'moc'

-- compile flags
var 'CFLAGS', {'-fPIC', '-fopenmp', '-Wall', '-Wextra', '-Isrc', '--std=c++1', '-O3'}
var 'LDFLAGS', {'-fPIC', '-fopenmp'}
var 'PKGS', {'Qt5Widgets'}

-- extra cli flags
public var 'XCFLAGS'
public var 'XLDFLAGS'
public var 'XPKGS'
public var 'XLIBS'

-- find all files for project
var 'SOURCES', _.wildcard 'src/**.cpp'
var 'HEADERS', _.wildcard 'src/**.h'
var 'QT_HEADERS', _.wildcard 'src/**.hh'

-- complete our flags
var 'PKGS', {PKGS, XPKGS}
var 'CFLAGS', {CFLAGS, XCFLAGS, _.pkgconfig.cflags PKGS}
var 'LDFLAGS', {LDFLAGS, LDCFLAGS}
var 'LIBS', {XLIBS, _.pkgconfig.libs PKGS}

-- determine our subtargets
var 'BINARY', "out/#{NAME}"
var 'OBJECTS', _.patsubst SOURCES, 'src/%.cpp', 'build/%.o'
var 'MOC_SOURCES', _.patsubst QT_HEADERS, 'src/%.hh', 'build/%.moc.cpp'
var 'MOC_OBJECTS', _.patsubst MOC_SOURCES, '%.cpp', '%.o'
var 'OBJECTS', {OBJECTS, MOC_OBJECTS}


-- build everything
with public default target 'all'
	\depends BINARY

-- clean build objects
with public target 'clean'
	\fn => _.cmd 'rm', '-f', ALL_OBJECTS, MOC_SOURCES

-- clean everything
with public target 'mrproper'
	\after 'clean'
	\fn => _.cmd 'rm', '-f', BINARY

-- build and run
with public target 'run'
	\depends BINARY
	\fn => _.cmd "./#{BINARY}"

-- produce the binary from all objects
with target BINARY
	\produces BINARY
	\depends OBJECTS
	\fn => _.cmd LD, LDFLAGS, '-o', @outfile, @infiles, LIBS
	\mkdirs!

-- produce the objects from the sources
with target OBJECTS, pattern: 'build/%.o'
	\produces 'build/%.o'
	\depends 'src/%.cpp'
	\depends => _.cdeps[CPP] @infile, CFLAGS
	\fn => _.cmd CPP, CFLAGS, '-o', @outfile, '-c', @infile
	\mkdirs!

-- produce the objects from the moc-generated sources
with target MOC_OBJECTS, pattern: 'build/%.moc.o'
	\produces 'build/%.moc.o'
	\depends 'build/%.moc.cpp'
	\fn => _.cmd CPP, CFLAGS, '-o', @outfile, '-c', @infile

-- generate moc sources from the qt headers
with target MOC_SOURCES, pattern: 'build/%.moc.cpp'
	\produces 'build/%.moc.cpp'
	\depends 'src/%.hh'
	\fn => _.cmd MOC, '-o', @outfile, @infile
	\mkdirs!

[[
var: string, Serializable -> Variable
	creates a variable in the global shared state

public: Variable -> Variable
	makes a variable overwritable with a CLI flag or through environment variables

target: string|array, TargetOptions? -> Target
	creates a target matching the given name or names, with the given options

public: Target -> Target
	makes a target listable on the CLI

default: Target -> Target
	makes a target run automatically if no target is specified

init: (nil -> nil) -> nil
	adds a function to run in the init environment after the CLI options are processed

typedef Serializable
| string
| boolean
| number
| nil
| array<Serializable>
| map<string|boolean|number, Serializable>
	a value that can be flattened and passed to another environment

typedef List
| nil
| string
| array<List>
	a list of strings that can get flattened to array<string> unambiguously

typedef TargetOptions: table
- pattern: string? [@name or '%']
	a pattern that is matched when trying the target, it is also used to fill in '%' in the target
- priority: int? [0]
	higher values make moonbuild try the target before lower-priority targets

class Target
- produces: List -> Target
	adds objects to the list of productions
- depends: List -> Target
	adds objects to the list of dependencies
- depends: (TargetContext -> List) -> Target
	adds objects to the list of dependencies when the target is first tried
- after: List -> Target
	adds targets to the ordering list
- fn: (TargetContext -> nil) -> Target
	adds a function to run to build the target
- sync: nil -> Target
	forces the target to run synchronously and sequentially
- mkdirs: nil -> Target
	always ensures the parent directories of the productions exist, creating them if they don't

class TargetContext
- name: string
	the name the target is running as
- infiles: List
	the list of input files
- infile: string?
	the first input file
- outfiles: List
	the list of output files
- outfile: string?
	the first output file

environment Global
- _ library
- VARIABLES
- standard Lua library

environment Top: Global
- target
- var
- init
- public
- default

environment Init: Global
- target
- var
]]
