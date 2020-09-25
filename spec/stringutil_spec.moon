describe 'stringutil', ->
	describe 'patsubst', ->
		import patsubst from require 'moonbuild.stringutil'

		test = (expected, source, patt, subst) ->
			it "substitutes #{source} into #{expected} with #{patt} and #{subst}", ->
				assert.equal expected, patsubst source, patt, subst

		testall = (tab) ->
			for a, b in pairs tab
				test b, a[1], a[2], a[3]

		describe 'handles just adding pre/suffix', ->
			testall {
				[{'a', '%', '_%'}]: '_a'
				[{'tx', '%', 'a_%'}]: 'a_tx'
				[{'a', '%', '%_'}]: 'a_'
				[{'tx', '%', '%_a'}]: 'tx_a'
				[{'a', '%', '_%_'}]: '_a_'
			}

		describe 'handles doing nothing', ->
			for str in *({'a', 'aa', 'tx'})
				test str, str, '%', '%'

		describe 'handles literal change', ->
			testall {
				[{'a', 'a', 'b'}]: 'b'
				[{'a', 'b', 'c'}]: 'a'
				[{'aa', 'a', 'b'}]: 'aa'
			}

		describe 'handles match change', ->
			testall {
				[{'-a_', '-%_', 'b'}]: 'b'
				[{'-a_', '-%', 'b'}]: 'b'
				[{'-a_', '%_', 'b'}]: 'b'
				[{'-a_', '_%-', 'b'}]: '-a_'
			}

		describe 'handles just removing pre/suffix', ->
			testall {
				[{'_a', '_%', '%'}]: 'a'
				[{'a_', '%_', '%'}]: 'a'
				[{'_a_', '_%_', '%'}]: 'a'
			}

		describe 'handles not matching', ->
			testall {
				[{'a-', '%_', '%'}]: 'a-'
				[{'-a', '_%', '%'}]: '-a'
				[{'-a-', '_%_', '%'}]: '-a-'
			}

		describe 'handles changing pre/suffix', ->
			testall {
				[{'a-', '%-', '%_'}]: 'a_'
				[{'-a', '-%', '_%'}]: '_a'
				[{'-a', '-%', '%_'}]: 'a_'
				[{'_a-', '_%-', '-%_'}]: '-a_'
			}

	describe 'splitsp', ->
		import splitsp from require 'moonbuild.stringutil'

		test = (expected, source) ->
			it "splits '#{source}' correctly", ->
				assert.same expected, splitsp source

		for source, expected in pairs {
			'a b c': {'a', 'b', 'c'}
			'abc': {'abc'}
			'': {}
			'   a b       c': {'a', 'b', 'c'}
			'    ': {}
			' ab c': {'ab', 'c'}
		}
			test expected, source
