describe 'fsutil', ->
	describe 'normalizepath', ->
		import normalizepath from require 'moonbuild.fsutil'

		test = (expected, source) ->
			it "normalizes #{source} correctly", ->
				assert.equal expected, normalizepath source

		testall = (tab) ->
			for a, b in pairs tab
				test b, a

		describe 'handles already normalized paths', ->
			testall {
				'.': '.'
				'..': '..'
				'../..': '../..'
				'/': '/'
				'/a': '/a'
				'/a/b': '/a/b'
				'a': 'a'
				'a/b': 'a/b'
			}

		describe 'trims leading slashes', ->
			testall {
				'a/': 'a'
				'a/b/': 'a/b'
				'/a/': '/a'
				'/a/b/': '/a/b'
			}

		describe 'normalizes absolute paths', ->
			testall {
				'/a/a/../b': '/a/b'
				'/a/./b': '/a/b'
				'/a/b/c/..': '/a/b'
				'/./a/./b/././.': '/a/b'
			}

		describe 'normalizes relative paths', ->
			testall {
				'../x/../../a': '../../a'
				'../x/../a': '../a'
				'x/..': '.'
				'../.': '..'
				'./a': 'a'
			}

	describe 'matchglob', ->
		import matchglob from require 'moonbuild.fsutil'

		test = (expected, source, glob) ->
			if expected
				it "matches #{glob} on #{source}", ->
					assert.equal source, matchglob source, glob
			else
				it "doesn't match #{glob} on #{source}", ->
					assert.equal nil, matchglob source, glob

		testall = (tab) ->
			for a, b in pairs tab
				test b, a[1], a[2]

		describe 'handles literal names', ->
			testall {
				[{'a', 'a'}]: true
				[{'a.b', 'a.b'}]: true
				[{'a/b', 'a/b'}]: true
				[{'..', '..'}]: true
			}

		describe 'doesn\'t treat things as special chars', ->
			testall {
				[{'a', '.'}]: false
				[{'a.b.c', '%S+'}]: false
				[{'%S+', '%S+'}]: true
				[{'%d', '%d'}]: true
				[{'a', '%S'}]: false
				[{'aaa', 'a+'}]: false
			}

		describe 'only matches fully', ->
			testall {
				[{'abcdef', 'bcde'}]: false
				[{'a/b/c', 'b/c'}]: false
				[{'a/b/c', 'a/b'}]: false
			}

		describe 'handles *', ->
			testall {
				[{'abcde', '*'}]: true
				[{'a/b/c/d', 'a/*/c/d'}]: true
				[{'a/b/c/d', 'a/*/d'}]: false
				[{'abcde', 'a*e'}]: true
				[{'abcde', 'a*f'}]: false
				[{'a/b/c/d/e', 'a/*/*/*/e'}]: true
				[{'a/b/c/d/e', 'a*/*/*e'}]: false
			}

		describe 'handles **', ->
			testall {
				[{'abcde', '**'}]: true
				[{'a/b/c/d', 'a/**/c/d'}]: true
				[{'abcde', 'a**e'}]: true
				[{'a/b/c/d/e', 'a/**/**/**/e'}]: true
				[{'a/b/c/d/e', 'a**e'}]: true
				[{'a/b/c/d/e', 'a/**/e'}]: true
				[{'a/b/c/d/e', 'a**f'}]: false
				[{'abcde', 'a**f'}]: false
			}
