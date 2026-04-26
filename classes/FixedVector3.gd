@tool
extends Resource
class_name FixedVector3

@export var x: int = 0:
	set(val):
		x = val
		if Engine.is_editor_hint():
			return
		if self.x_setter_callback != null:
			self.x_setter_callback.call()
		if self.universal_setter_callback != null:
			self.universal_setter_callback.call()

@export var y: int = 0:
	set(val):
		y = val
		if Engine.is_editor_hint():
			return
		if self.y_setter_callback != null:
			self.y_setter_callback.call()
		if self.universal_setter_callback != null:
			self.universal_setter_callback.call()

@export var z: int = 0:
	set(val):
		z = val
		if Engine.is_editor_hint():
			return
		if self.z_setter_callback != null:
			self.z_setter_callback.call()
		if self.universal_setter_callback != null:
			self.universal_setter_callback.call()

static var UP: FixedVector3 = FixedVector3.new(0, FixedInt.FIXED_ONE, 0)
static var RIGHT: FixedVector3 = FixedVector3.new(FixedInt.FIXED_ONE, 0, 0)

var x_setter_callback: Callable = func() -> void: return
var y_setter_callback: Callable = func() -> void: return
var z_setter_callback: Callable = func() -> void: return
var universal_setter_callback: Callable = func() -> void: return

func _init(x_inc: int = 0, y_inc: int = 0, z_inc: int = 0) -> void:
	self.x = x_inc
	self.y = y_inc
	self.z = z_inc

static func from_vec3(val: Vector3) -> FixedVector3:
	var ret_vec: FixedVector3 = FixedVector3.new()

	ret_vec.x = FixedInt.from_float(val.x)
	ret_vec.y = FixedInt.from_float(val.y)
	ret_vec.z = FixedInt.from_float(val.z)

	return ret_vec

static func to_vec3(val: FixedVector3) -> Vector3:
	var ret_vec: Vector3 = Vector3()

	ret_vec.x = FixedInt.to_float(val.x)
	ret_vec.y = FixedInt.to_float(val.y)
	ret_vec.z = FixedInt.to_float(val.z)

	return ret_vec

static func add(vec1: FixedVector3, vec2: FixedVector3) -> FixedVector3:
	var ret_vec: FixedVector3 = FixedVector3.new()

	ret_vec.x = vec1.x + vec2.x
	ret_vec.y = vec1.y + vec2.y
	ret_vec.z = vec1.z + vec2.z

	return ret_vec

static func sub(vec1: FixedVector3, vec2: FixedVector3) -> FixedVector3:
	var ret_vec: FixedVector3 = FixedVector3.new()

	ret_vec.x = vec1.x - vec2.x
	ret_vec.y = vec1.y - vec2.y
	ret_vec.z = vec1.z - vec2.z

	return ret_vec

static func mul(vec: FixedVector3, num: int) -> FixedVector3:
	var ret_vec: FixedVector3 = FixedVector3.new()

	ret_vec.x = FixedInt.mul(vec.x, num)
	ret_vec.y = FixedInt.mul(vec.y, num)
	ret_vec.z = FixedInt.mul(vec.z, num)

	return ret_vec

static func vec_mul(vec1: FixedVector3, vec2: FixedVector3) -> FixedVector3:
	var ret_vec: FixedVector3 = FixedVector3.new()

	ret_vec.x = FixedInt.mul(vec1.x, vec2.x)
	ret_vec.y = FixedInt.mul(vec1.y, vec2.y)
	ret_vec.z = FixedInt.mul(vec1.z, vec2.z)

	return ret_vec

static func div(vec: FixedVector3, num: int) -> FixedVector3:
	var ret_vec: FixedVector3 = FixedVector3.new()

	ret_vec.x = FixedInt.div(vec.x, num)
	ret_vec.y = FixedInt.div(vec.y, num)
	ret_vec.z = FixedInt.div(vec.z, num)

	return ret_vec

static func lerp(from: FixedVector3, to: FixedVector3, weight: int) -> FixedVector3:
	var ret: FixedVector3 = FixedVector3.new()

	ret.x = FixedInt.lerp(from.x, to.x, weight)
	ret.y = FixedInt.lerp(from.y, to.y, weight)
	ret.z = FixedInt.lerp(from.z, to.z, weight)

	return ret

static func basis_looking_at(
	target: FixedVector3, 
	up_axis: FixedVector3 = FixedVector3.UP, 
	use_model_front: bool = false, 
	return_basis: bool = false) -> Variant: # Array[Array]:
	var v_z: FixedVector3 = target.normalized()
	if !use_model_front:
		v_z.x = -v_z.x
		v_z.y = -v_z.y
		v_z.z = -v_z.z

	var v_x: FixedVector3 = up_axis.cross(v_z)
	if v_x.is_zero_approx():
		v_x = up_axis.cross( \
				FixedVector3.RIGHT if \
					(abs(up_axis.x) <= abs(up_axis.y) && abs(up_axis.x) <= abs(up_axis.z)) \
					else FixedVector3.UP
		).normalized()

	v_x.normalize()

	var v_y: FixedVector3 = v_z.cross(v_x).normalized()

	if return_basis:
		return Basis(
			FixedVector3.to_vec3(v_x),
			FixedVector3.to_vec3(v_y),
			FixedVector3.to_vec3(v_z)
		)

	return [
		[v_x.x, v_y.x, v_z.x],
		[v_x.y, v_y.y, v_z.y],
		[v_x.z, v_y.z, v_z.z]
	]


# Retrieves euler rotation [rewritten from Godot Source Code: https://github.com/godotengine/godot/blob/master/core/math/basis.cpp]
static func basis_get_euler(basis: Array, order: EulerOrder = EulerOrder.EULER_ORDER_YXZ) -> FixedVector3:
	var euler: FixedVector3 = FixedVector3.new()

	match order:
		EulerOrder.EULER_ORDER_XYZ:
			var m12: int = basis[1][2]

			if m12 < (FixedInt.FIXED_ONE - 1):

				if m12 > -(FixedInt.FIXED_ONE - 1):
					
					# is this a pure X rotation?
					if basis[1][0] == 0 && \
						basis[0][1] == 0 && \
						basis[0][2] == 0 && \
						basis[2][0] == 0 && \
						basis[0][0] == FixedInt.FIXED_ONE:
						# return the simplest form (human friendlier in editor and scripts)
						euler.x = FixedInt.atan2(-m12, basis[1][1])
						euler.y = 0
						euler.z = 0
					
					else:
						euler.x = FixedInt.asin(-m12)
						euler.y = FixedInt.atan2(basis[0][2], basis[2][2])
						euler.z = FixedInt.atan2(basis[1][0], basis[1][1])

				else: # m12 == -1
					euler.x = FixedInt.FIXED_PI_DIV_2
					euler.y = FixedInt.atan2(basis[0][1], basis[0][0])
					euler.z = 0

			else:
				euler.x = -FixedInt.FIXED_PI_DIV_2
				euler.y = -FixedInt.atan2(basis[0][1], basis[0][0])
				euler.z = 0

			return euler

		EulerOrder.EULER_ORDER_XZY:
			var sz: int = basis[0][1]

			if sz < (FixedInt.FIXED_ONE - 1):

				if sz > -(FixedInt.FIXED_ONE - 1):
					euler.x = FixedInt.atan2(basis[2][1], basis[1][1])
					euler.y = FixedInt.atan2(basis[0][2], basis[0][0])
					euler.z = FixedInt.asin(-sz)

				else: # sz == -1
					euler.x = -FixedInt.atan2(basis[1][2], basis[2][2])
					euler.y = 0
					euler.z = FixedInt.FIXED_PI_DIV_2

			else: # sz == 1
				euler.x = -FixedInt.atan2(basis[1][2], basis[2][2])
				euler.y = 0
				euler.z = -FixedInt.FIXED_PI_DIV_2

			return euler
		
		EulerOrder.EULER_ORDER_YXZ:
			var m12: int = basis[1][2]

			if m12 < (FixedInt.FIXED_ONE - 1):

				if m12 > -(FixedInt.FIXED_ONE - 1):
					
					# is this a pure X rotation?
					if basis[1][0] == 0 && \
						basis[0][1] == 0 && \
						basis[0][2] == 0 && \
						basis[2][0] == 0 && \
						basis[0][0] == FixedInt.FIXED_ONE:
						# return the simplest form (human friendlier in editor and scripts)
						euler.x = FixedInt.atan2(-m12, basis[1][1])
						euler.y = 0
						euler.z = 0
					
					else:
						euler.x = FixedInt.asin(-m12)
						euler.y = FixedInt.atan2(basis[0][2], basis[2][2])
						euler.z = FixedInt.atan2(basis[1][0], basis[1][1])

				else: # m12 == -1
					euler.x = FixedInt.FIXED_PI_DIV_2
					euler.y = FixedInt.atan2(basis[0][1], basis[0][0])
					euler.z = 0

			else: # m12 == 1
				euler.x = -FixedInt.FIXED_PI_DIV_2
				euler.y = -FixedInt.atan2(basis[0][1], basis[0][0])
				euler.z = 0

			return euler

		EulerOrder.EULER_ORDER_YZX:
			var sz: int = basis[1][0]

			if sz < (FixedInt.FIXED_ONE - 1):

				if sz > -(FixedInt.FIXED_ONE - 1):
					euler.x = FixedInt.atan2(-basis[1][2], basis[1][1])
					euler.y = FixedInt.atan2(-basis[2][0], basis[0][0])
					euler.z = FixedInt.asin(sz)

				else: # sz == -1
					euler.x = FixedInt.atan2(basis[2][1], basis[2][2])
					euler.y = 0
					euler.z = -FixedInt.FIXED_PI_DIV_2

			else: # sz == 1
				euler.x = FixedInt.atan2(basis[2][1], basis[2][2])
				euler.y = 0
				euler.z = FixedInt.FIXED_PI_DIV_2

			return euler

		EulerOrder.EULER_ORDER_ZXY:
			var sx: int = basis[2][1]

			if sx < (FixedInt.FIXED_ONE - 1):

				if sx > -(FixedInt.FIXED_ONE - 1):
					euler.x = FixedInt.asin(sx)
					euler.y = FixedInt.atan2(-basis[2][0], basis[2][2])
					euler.z = FixedInt.atan2(-basis[0][1], basis[1][1])

				else: # sx == -1
					euler.x = -FixedInt.FIXED_PI_DIV_2
					euler.y = FixedInt.atan2(basis[0][2], basis[0][0])
					euler.z = 0

			else: # sx == 1
				euler.x = FixedInt.FIXED_PI_DIV_2
				euler.y = FixedInt.atan2(basis[0][2], basis[0][0])
				euler.z = 0

			return euler

		EulerOrder.EULER_ORDER_ZYX:
			var sy: int = basis[2][0]

			if sy < (FixedInt.FIXED_ONE - 1):

				if sy > -(FixedInt.FIXED_ONE - 1):
					euler.x = FixedInt.atan2(basis[2][1], basis[2][2])
					euler.y = FixedInt.asin(-sy)
					euler.z = FixedInt.atan2(basis[1][0], basis[0][0])

				else: # sy == -1
					euler.x = 0
					euler.y = FixedInt.FIXED_PI_DIV_2
					euler.z = -FixedInt.atan2(basis[0][1], basis[1][1])

			else: # sy == 1
				euler.x = 0
				euler.y = -FixedInt.FIXED_PI_DIV_2
				euler.z = -FixedInt.atan2(basis[0][1], basis[1][1])

			return euler

	return euler

func dot(vec2: FixedVector3) -> int:
	var res: int = 0
	res += FixedInt.mul(self.x, vec2.x)
	res += FixedInt.mul(self.y, vec2.y)
	res += FixedInt.mul(self.z, vec2.z)
	return res

func dot_2d(vec2: FixedVector3) -> int:
	var res: int = 0
	res += FixedInt.mul(self.x, vec2.x)
	# res += FixedInt.mul(self.y, vec2.y)
	res += FixedInt.mul(self.z, vec2.z)
	return res

func cross(vec2: FixedVector3) -> FixedVector3:
	return FixedVector3.new(
		FixedInt.mul(self.y, vec2.z) - FixedInt.mul(self.z, vec2.y),
		FixedInt.mul(self.z, vec2.x) - FixedInt.mul(self.x, vec2.z),
		FixedInt.mul(self.x, vec2.y) - FixedInt.mul(self.y, vec2.x)
	)

	# return FixedInt.mul(self.z, vec2.x) - FixedInt.mul(self.x, vec2.z)

func length() -> int:
	var length_sqrd: int = self.length_squared()

	if length_sqrd == 0:
		return 0

	var lgth: int = FixedInt.sqrt_64(length_sqrd)
	if lgth == 0:
		return FixedInt.FIXED_ONE

	return lgth

func length_2d() -> int: # returns length projected across the XZ plane
	var pow1: int = FixedInt.mul(self.x, self.x)
	var pow2: int = FixedInt.mul(self.z, self.z)

	# print(str(pow1) + " " + str(pow2) + ' ' + str(FixedInt.sqrt_64(pow1 + pow2)))
	return FixedInt.sqrt_64(pow1 + pow2)

func length_squared() -> int:
	var ret: int = FixedInt.mul(self.x, self.x) \
		+ FixedInt.mul(self.y, self.y) \
		+ FixedInt.mul(self.z, self.z)
											  
	# squaring a fixed point number smaller than 15 will be 0
	# which means ret can be 0
	if (ret == 0) && (self.x != 0 || self.y != 0 || self.z != 0):
		return FixedInt.FIXED_ONE # gotta return something
	return ret

func distance_to(vec: FixedVector3) -> int:
	return FixedVector3.sub(vec, self).length()

func distance_to_2d(vec: FixedVector3) -> int:
	return FixedVector3.sub(vec, self).length_2d()

func distance_squared_to(vec: FixedVector3) -> int:
	return FixedVector3.sub(vec, self).length_squared()

func direction_to(vec2: FixedVector3) -> FixedVector3:
	var ret: FixedVector3 = FixedVector3.new()
	ret.x = vec2.x - self.x
	ret.y = vec2.y - self.y
	ret.z = vec2.z - self.z
	ret.normalize()
	return ret

func angle(axis: Vector3) -> int:
	var yaw: Callable = func() -> int: 
		return FixedInt.atan2(self.y, self.x)

	match axis:
		Vector3.UP, Vector3.DOWN:
			return FixedInt.atan2(-self.z, 
			FixedInt.sqrt_64(
				FixedInt.mul(self.x, self.x) + FixedInt.mul(self.y, self.y)
				)
			)   
		Vector3.LEFT, Vector3.RIGHT:
			var _yaw: int = yaw.call()
			return FixedInt.atan2(
				FixedInt.mul(
					self.y, FixedInt.cos(_yaw)
				) + FixedInt.mul(
					x, FixedInt.sin(_yaw)
				), self.z
			)
		Vector3.FORWARD, Vector3.BACK:
			return yaw.call()
	return 0

func angle_to(target: FixedVector3, _axis: Vector3 = Vector3.UP) -> int: # << CONVERT THIS 
	var del_x: int = self.x - target.x
	var del_z: int = self.z - target.z

	var slope: int = FixedInt.div(del_x, del_z)

	var ang: int = FixedInt.atan(slope)

	if self.z > target.z:
		ang += FixedInt.FIXED_PI
	
	return ang

func rotated(axis: FixedVector3, p_rotation: int) -> FixedVector3:
	var v: FixedVector3 = FixedVector3.new(self.x, self.y, self.z)
	v.rotate(axis,  p_rotation) 
	return v

func rotate(_axis: FixedVector3, ang: int) -> FixedVector3: # <-- simplify this; focus on just XZ plane
	
	var s: int = FixedInt.sin(ang)
	var c: int = FixedInt.cos(ang)


	var x_old: int = int(self.x)
	# var y_old := int(self.y)
	var z_old: int = int(self.z)

	self.z = FixedInt.mul(c, z_old) - FixedInt.mul(s, x_old)
	self.x = FixedInt.mul(s, z_old) + FixedInt.mul(c, x_old)

	return self

func normalized() -> FixedVector3:
	var v: FixedVector3 = FixedVector3.new(self.x, self.y, self.z)
	v.normalize()
	return v

# based on snopek games' SGPysics2D implementation, translated into 3d
func normalize() -> void:
	var x_abs: int = abs(self.x)
	var y_abs: int = abs(self.y)
	var z_abs: int = abs(self.z)

	# values under 2048 give imprecise results.
	# we only care about direction, so we can increase the vector's magnitude as a workaround
	if ((self.x != 0 && x_abs < 2048) || (self.y != 0 && y_abs < 2048) || (self.z != 0 && z_abs < 2048)):

		# need to watch out for values that may overflow 64 bit integers
		# 1482910 = sqrt(MAX_SIGNED_64BIT_NUMBER) / 2048

		if (x_abs >= 1482910):
			self.x = 65536 if self.x > 0 else -65536
			self.y = 0
			self.z = 0
		
		elif (y_abs >= 1482910):
			self.x = 0
			self.y = 65536 if self.x > 0 else -65536
			self.z = 0

		elif (z_abs >= 1482910):
			self.x = 0
			self.y = 0
			self.z = 65536 if self.x > 0 else -65536

		else:
			# multiply xyz by 2048
			var x_big: int = self.x << 11 # bit shifting is much faster than regular multiplication
			var y_big: int = self.y << 11
			var z_big: int = self.z << 11

			var lgth: int = FixedVector3.new(
					x_big, 
					y_big, 
					z_big
				).length()

			if lgth != 0:
				self.x = FixedInt.div(x_big, lgth)
				self.y = FixedInt.div(y_big, lgth)
				self.z = FixedInt.div(z_big, lgth)

	else:
		var lgth: int = self.length()
		if lgth != 0:
			self.x = FixedInt.div(self.x, lgth)
			self.y = FixedInt.div(self.y, lgth)
			self.z = FixedInt.div(self.z, lgth)

func is_zero_approx()-> bool:
	return self.x == FixedInt.FIXED_ZERO && self.y == FixedInt.FIXED_ZERO && self.z == FixedInt.FIXED_ZERO

# unused
func to_quaternion() -> Quaternion:
	var cr: int = FixedInt.cos(FixedInt.mul(self.x, FixedInt.FIXED_HALF))
	var sr: int = FixedInt.sin(FixedInt.mul(self.x, FixedInt.FIXED_HALF))
	var cp: int = FixedInt.cos(FixedInt.mul(self.y, FixedInt.FIXED_HALF))
	var sp: int = FixedInt.sin(FixedInt.mul(self.y, FixedInt.FIXED_HALF))
	var cy: int = FixedInt.cos(FixedInt.mul(self.z, FixedInt.FIXED_HALF))
	var sy: int = FixedInt.sin(FixedInt.mul(self.z, FixedInt.FIXED_HALF))

	var quat: Quaternion = Quaternion()
	quat.w = (FixedInt.mul(FixedInt.mul(cr, cp), cy) + FixedInt.mul(FixedInt.mul(sr, sp), sy)) / 65536
	quat.x = (FixedInt.mul(FixedInt.mul(sr, cp), cy) - FixedInt.mul(FixedInt.mul(cr, sp), sy)) / 65536
	quat.y = (FixedInt.mul(FixedInt.mul(cr, sp), cy) + FixedInt.mul(FixedInt.mul(sr, cp), sy)) / 65536
	quat.z = (FixedInt.mul(FixedInt.mul(cr, cp), sy) - FixedInt.mul(FixedInt.mul(sr, sp), cy)) / 65536

	return quat
