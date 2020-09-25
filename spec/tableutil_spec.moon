describe 'tableutil', ->
	describe 'sortedpairs', ->
		import sortedpairs from require 'moonbuild.tableutil'

		for src, dst in pairs {
			[{a: '1', c: 2, b: 3}]: {'a', '1', 'b', 3, 'c', 2}
			[{5, 4, 3}]: {1, 5, 2, 4, 3, 3}
		}
			it "works for #{src}", ->
				i = 1
				for k, v in sortedpairs src
					assert.equal k, dst[i]
					assert.equal v, dst[i+1]
					i += 2

	describe 'min and max', ->
		import min, max from require 'moonbuild.tableutil'

		for src, dst in pairs {
			[{1, 2, 3, 4, 5}]: {1, 5}
			[{5, 4, 3, 2, 1}]: {1, 5}
			[{2, 4, 5, 1, 3}]: {1, 5}
			[{1, 1, 1, 1, 1}]: {1, 1}
			[{1}]: {1, 1}
		}
			it "min of #{table.concat src, ','} is #{dst[1]}", ->
				assert.equal dst[1], min src
			it "max of #{table.concat src, ','} is #{dst[2]}", ->
				assert.equal dst[2], max src

	describe 'foreach', ->
		import foreach from require 'moonbuild.tableutil'

		src = {1, 2, 5, '79'}
		testall = (name, rst, fn) ->
			it name, ->
				assert.same rst, foreach src, fn


		testall 'works with tostring', {'1', '2', '5', '79'}, tostring
		testall 'works with tonumber', {1, 2, 5, 79}, tonumber
		testall 'works with some mix of tonumber and comparison', {false, false, true, true}, => 3<tonumber @

	describe 'first', ->
		import first from require 'moonbuild.tableutil'

		test = (name, src, rst, fn) ->
			it name, ->
				assert.equal rst, (first src, fn)

		test 'works with == for first of list', {1, 3, 5}, 1, => @==1
		test 'works with == for something else', {1, 3, 5}, 3, => @==3
		test 'works with == for absent element', {1, 3, 5}, nil, => @==2

	describe 'exclude', ->
		import exclude from require 'moonbuild.tableutil'
		unpack or= table.unpack

		test = (name, src, rst, ...) ->
			rest = {...}
			it name, ->
				assert.equal src, exclude src, unpack rest
				assert.same rst, src

		test 'works with nothing', {1, 2, 3}, {1, 2, 3}
		test 'works with absent elements', {1, 2, 3}, {1, 2, 3}, 4, 5, 6
		test 'works with some elements', {1, 2, 3}, {1}, 2, 3
		test 'works with all elements', {1, 2, 3}, {}, 1, 2, 3
		test 'works with a mix', {1, 2, 3}, {1, 3}, 2, 4, 5

	describe 'flatten', ->
		import flatten from require 'moonbuild.tableutil'

		test = (name, src, rst) ->
			it name, ->
				assert.same rst, flatten src

		test 'works with empty table', {}, {}
		test 'works with flat table', {1, 2, 3}, {1, 2, 3}
		test 'works with one level', {1, {2}, {3}}, {1, 2, 3}
		test 'works with multiple levels', {{{1, {{2}}}, 3}}, {1, 2, 3}
		test 'skips maps', {1, {a: 2}, 3}, {1, {a: 2}, 3}
