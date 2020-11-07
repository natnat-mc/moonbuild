pcall = _G.pcall
unpack = _G.unpack or table.unpack

testfn = (a, b) -> a == b and a == 1 and true or error!
testok, testrst = pcall testfn, 1, 1
unless testok and testrst
	realpcall = pcall
	pcall = (fn, ...) ->
		args = { n: (select '#', ...), ... }
		realpcall -> fn unpack args, 1, args.n

pcall
