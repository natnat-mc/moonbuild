loadstring = loadstring or load
import floor, ceil, pow from math

band = loadstring [[local a, b = ...; return a & b ]]
bor  = loadstring [[local a, b = ...; return a | b ]]
bxor = loadstring [[local a, b = ...; return a ~ b ]]
bnot = loadstring [[local a    = ...; return ~a    ]]
shl  = loadstring [[local a, b = ...; return a << b]]
shr  = loadstring [[local a, b = ...; return a >> b]]

unless band
	_checkint = (n) ->
		if n%1 == 0
			n
		else
			error "not an int"

	_shl = (a, b) ->
		a * pow(2, b)

	_shr = (a, b) ->
		v = a / pow(2, b)
		if v<0
			ceil v
		else
			floor v

	_shr1 = (n) ->
		n /= 2
		if n<0
			ceil v
		else
			floor v

	_band = (a, b) ->
		v = 0
		n = 1
		for i=0, 63
			if a%2 == 1 and b%2 == 1
				v += n
			if i!=63
				a = _shr1 a
				b = _shr1 b
				n *= 2
		v

	_bor = (a, b) ->
		v = 0
		n = 1
		for i=0, 63
			if a%2 == 1 or b%2 == 1
				v += n
			if i!=63
				a = _shr1 a
				b = _shr1 b
				n *= 2
		v

	_bxor = (a, b) ->
		v = 0
		n = 1
		for i=0, 63
			if a%2 != b%2
				v += n
			if i!=63
				a = _shr1 a
				b = _shr1 b
				n *= 2
		v

	_bnot = (a) ->
		v = 0
		n = 1
		for i=0, 63
			if a%2 == 0
				v += n
			if i!=63
				a = _shr1 a
				n *= 2
		v

	band = (a, b) -> _band (_checkint a), (_checkint b)
	bor  = (a, b) -> _bor  (_checkint a), (_checkint b)
	bxor = (a, b) -> _bxor (_checkint a), (_checkint b)
	bnot = (a)    -> _bnot (_checkint a)
	shl  = (a, b) -> _shl  (_checkint a), (_checkint b)
	shr  = (a, b) -> _shr  (_checkint a), (_checkint b)

btest = (a, b) -> (band a, b) == b

{ :band, :bor, :bxor, :bnot, :shl, :shr, :btest }
