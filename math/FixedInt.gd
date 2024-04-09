class_name FixedInt

const FIXED_ZERO := 0
const FIXED_ONE := 65536
const FIXED_TWO := 131072
const FIXED_PI := 205887
const FIXED_TAU := 411774
const FIXED_PI_DIV_2 := 102943

# also copied from SGPhysics2D, which copied from wikipedia. theft is an art
# https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_numeral_system_.28base_2.29
# ALSO also; woulda really like to prototype this onto int but OH WELL
static func sqrt_64(num: int) -> int:
	if num == FIXED_ZERO:
		return FIXED_ZERO

	var neg: bool = num < FIXED_ZERO
	if neg:
		num = -num

	var res: int = FIXED_ZERO
	var bit: int = 1 << 62

	# start at highest power of four thats less than or equal to num
	while bit > num:
		bit = bit >> 2

	while bit != 0:
		if num >= res + bit:
			num -= res + bit
			res = (res >> 1) + bit
		else:
			res >>= 1
		bit >>= 2

	return -res if neg else res

static func from_int(val: int) -> int:
	return val << 16

static func mul(val1: int, val2: int) -> int:
	# there may need to be some overflow checks above this
	# but im assuming for now that gdscript is incapable from performing those
	return (val1 * val2) >> 16

static func div(num: int, den: int) -> int:
	if den == 0: return 0
	return (num << 16) / den

# // Adapted from the fpm library: https://github.com/MikeLankamp/fpm
# // Copyright 2019 Mike Lankamp
# // License: MIT
static func sin(num: int) -> int:
	# // This sine uses a fifth-order curve-fitting approximation originally
	# // described by Jasper Vijn on coranac.com which has a worst-case
	# // relative error of 0.07% (over [-pi:pi]).

	# // Turn x from [0..2*PI] domain into [0..4] domain
	var x: int = num % FIXED_TAU
	x = FixedInt.div(x, FIXED_PI_DIV_2)

	# Take x modulo one rotation, so [-4..+4].
	if x < FixedInt.from_int(0):
		x += FixedInt.from_int(4)

	var sig := FixedInt.from_int(+1)
	if x > FixedInt.from_int(2):
		# Reduce domain to [0..2].
		sig = FixedInt.from_int(-1)
		x -= FixedInt.from_int(2)

	if x > FixedInt.from_int(1):
		# Reduce domain to [0..1].
		x = FixedInt.from_int(2) - x

	var x2 := FixedInt.mul(x, x)
	
	return FixedInt.mul(FixedInt.mul(sig, x), FIXED_PI - FixedInt.mul(x2,
			FIXED_TAU - FixedInt.from_int(5) - FixedInt.mul(x2, (FIXED_PI - FixedInt.from_int(3)))
		)) >> 1

static func cos(num: int) -> int:
	return FixedInt.sin(num + FIXED_PI_DIV_2)

static func acos(num: int) -> int:
	if num < -FIXED_ONE || num > FIXED_ONE:
		return FIXED_ZERO

	if num == -FIXED_ONE:
		return FIXED_PI

	var yy := FIXED_ONE - FixedInt.mul(num, num)
	return FixedInt.mul(FIXED_TWO, FixedInt.atan_div(FixedInt.sqrt_64(yy << 16), FIXED_ONE + num))
	
# // Adapted from the fpm library: https://github.com/MikeLankamp/fpm
# // Copyright 2019 Mike Lankamp
# // License: MIT
static func atan2(this: int, num: int) -> int:
	if this == FIXED_ZERO:
		return FIXED_PI if num > FIXED_ZERO else -FIXED_PI_DIV_2
	if num < FIXED_ZERO:
		return FIXED_PI_DIV_2 if this > FIXED_ZERO else -FIXED_PI_DIV_2

	var ret := FixedInt.atan_div(this, num)

	if num < FIXED_ZERO:
		return ret + FIXED_PI if this >= FIXED_ZERO else ret - FIXED_PI

	return ret

# // Adapted from the fpm library: https://github.com/MikeLankamp/fpm
# // Copyright 2019 Mike Lankamp
# // License: MIT
static func atan_div(p_y: int, p_x: int) -> int:
	if p_y < FIXED_ZERO:
		if p_x < FIXED_ZERO:
			return FixedInt.atan_div(-p_y, -p_x)
		return -FixedInt.atan_div(-p_y, p_x)
	
	if p_x < FIXED_ZERO:
		return -FixedInt.atan_div(p_y, p_x)

	if p_y > p_x:
		return FIXED_PI_DIV_2 - FixedInt.atan_sanitized(FixedInt.div(p_x, p_y))

	return FixedInt.atan_sanitized(FixedInt.div(p_y, p_x))

# // Adapted from the fpm library: https://github.com/MikeLankamp/fpm
# // Copyright 2019 Mike Lankamp
# // License: MIT
static func atan_sanitized(p_x: int) -> int:
	var a := 5089   #  0.0776509570923569
	var b := -18837 # -0.2874298095703125
	var c := 65220  #  0.999755859375 (PI_DIV_4 - A - B)

	var xx = FixedInt.mul(p_x, p_x)
	return FixedInt.mul(FixedInt.mul(FixedInt.mul(a, xx + b), xx + c), p_x)

static func deg2rads(deg: int) -> int: 				# 180
	return FixedInt.mul(deg, FixedInt.div(FIXED_PI, 11796480)) 
	# return FixedInt.div(FixedInt.mul(deg, FIXED_PI), 11796480)