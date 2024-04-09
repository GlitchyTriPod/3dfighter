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

var x_setter_callback #: Callable 
var y_setter_callback
var z_setter_callback
var universal_setter_callback 

func _init(x_inc: int = 0, y_inc: int = 0, z_inc: int = 0):
	self.x = x_inc
	self.y = y_inc
	self.z = z_inc

static func from_vec3(val: Vector3) -> FixedVector3:
	var ret_vec = FixedVector3.new()

	ret_vec.x = int(val.x * 65536)
	ret_vec.y = int(val.y * 65536)
	ret_vec.z = int(val.z * 65536)

	return ret_vec

static func to_vec3(val: FixedVector3) -> Vector3:
	var ret_vec = Vector3()

	ret_vec.x = float(val.x / 65536.0)
	ret_vec.y = float(val.y / 65536.0)
	ret_vec.z = float(val.z / 65536.0)

	return ret_vec

static func add(vec1: FixedVector3, vec2: FixedVector3) -> FixedVector3:
	var ret_vec = FixedVector3.new()

	ret_vec.x = vec1.x + vec2.x
	ret_vec.y = vec1.y + vec2.y
	ret_vec.z = vec1.z + vec2.z

	return ret_vec

static func sub(vec1: FixedVector3, vec2: FixedVector3) -> FixedVector3:
	var ret_vec = FixedVector3.new()

	ret_vec.x = vec1.x - vec2.x
	ret_vec.y = vec1.y - vec2.y
	ret_vec.z = vec1.z - vec2.z

	return ret_vec

static func mul(vec: FixedVector3, num: int) -> FixedVector3:
	var ret_vec = FixedVector3.new()

	ret_vec.x = FixedInt.mul(vec.x, num)
	ret_vec.y = FixedInt.mul(vec.y, num)
	ret_vec.z = FixedInt.mul(vec.z, num)

	return ret_vec

static func div(vec: FixedVector3, num: int) -> FixedVector3:
	var ret_vec = FixedVector3.new()

	ret_vec.x = FixedInt.div(vec.x, num)
	ret_vec.y = FixedInt.div(vec.y, num)
	ret_vec.z = FixedInt.div(vec.z, num)

	return ret_vec

func dot(vec2: FixedVector3) -> int:
	var res := 0
	res += FixedInt.mul(self.x, vec2.x)
	res += FixedInt.mul(self.y, vec2.y)
	res += FixedInt.mul(self.z, vec2.z)
	return res

# func cross(vec2: FixedVector3) -> int:
# 	pass

func length() -> int:
	var length_sqrd := self.length_squared()

	if length_sqrd == 0:
		return 0

	var lgth = FixedInt.sqrt_64(length_sqrd)
	if lgth == 0:
		return 1

	return lgth

func length_2d() -> int: # returns length projected across the XZ plane
	var pow1 = FixedInt.mul(self.x, self.x)
	var pow2 = FixedInt.mul(self.z, self.z)

	# print(str(pow1) + " " + str(pow2) + ' ' + str(FixedInt.sqrt_64(pow1 + pow2)))
	return FixedInt.sqrt_64(pow1 + pow2)

func length_squared() -> int:
	var ret := FixedInt.mul(self.x, self.x) \
		+ FixedInt.mul(self.y, self.y) \
		+ FixedInt.mul(self.z, self.z)
											  
	# squaring a fixed point number smaller than 15 will be 0
	# which means ret can be 0
	if (ret == 0) && (self.x != 0 || self.y != 0 || self.z != 0):
		return 1 # gotta return something
	return ret

func distance_to(vec: FixedVector3) -> int:
	return FixedVector3.sub(vec, self).length()

func distance_to_2d(vec: FixedVector3) -> int:
	return FixedVector3.sub(vec, self).length_2d()

func distance_squared_to(vec: FixedVector3) -> int:
	return FixedVector3.sub(vec, self).length_squared()

func direction_to(vec2: FixedVector3) -> FixedVector3:
	var ret := FixedVector3.new()
	ret.x = vec2.x - self.x
	ret.y = vec2.y - self.y
	ret.z = vec2.z - self.z
	ret.normalize()
	return ret

func angle(axis: Vector3) -> int:
	var yaw := func() -> int: 
		return FixedInt.atan2(self.y, self.x)

	match axis:
		Vector3.UP, Vector3.DOWN:
			return FixedInt.atan2(-self.z, 
			FixedInt.sqrt_64(
				FixedInt.mul(self.x, self.x) + FixedInt.mul(self.y, self.y)
				)
			)   
		Vector3.LEFT, Vector3.RIGHT:
			var _yaw = yaw.call()
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

	var dist = self.distance_to_2d(target)

	# print( dist)

	var divd = FixedInt.div(self.x - target.x,dist)

	# print (str(divd) + " " + str(dist))

	var an = FixedInt.div(self.x - target.x, self.distance_to_2d(target))

	# print(an)
	return FixedInt.acos(an)
	# return FixedInt.atan2((self.x - target.x), self.z - target.z)

	# var dot_prod = self.dot(target)
	# var mag1 = self.length()
	# var mag2 = target.length()

	# var cos_theta = clamp(FixedInt.div(dot_prod, FixedInt.mul(mag1, mag2)), -65536, 65536)

	# return FixedInt.acos(cos_theta)

	# var s := FixedVector3.new()
	# var t := FixedVector3.new()
	# match axis:
	#     Vector3.FORWARD, Vector3.BACK:
	#         s.x = self.x
	#         s.y = self.y
	#         t.x = target.x
	#         t.y = target.y        
	#     Vector3.UP, Vector3.DOWN:
	#         s.x = self.x
	#         s.z = self.z
	#         t.x = target.x
	#         t.z = target.z        
	#     Vector3.LEFT, Vector3.RIGHT:
	#         s.y = self.y
	#         s.z = self.z
	#         t.y = target.y
	#         t.z = target.z
		
	# var dot_val := s.dot(t)
	# var mag1 := s.length()
	# var mag2 := t.length()

	# var mag_prod := FixedInt.mul(mag1, mag2)

	# var cos_angle := 0
	# if mag_prod != 0:
	#     cos_angle = FixedInt.div(dot_val, FixedInt.mul(mag1, mag2))

	# return FixedInt.acos(clamp(cos_angle, -65536, 65536))
	
func rotated(axis: FixedVector3, p_rotation: int) -> FixedVector3:
	var v := FixedVector3.new(self.x, self.y, self.z)
	v.rotate(axis,  p_rotation) # <-- i think this might cause problems but im not sure.
	# v = FixedVector3.mul(v, self.length())            # should i really be adding rotation to the -current- angle?
	return v

func rotate(_axis, ang: int) -> FixedVector3: # <-- simplify this; focus on just XZ plane
	
	var s = FixedInt.sin(ang)
	var c = FixedInt.cos(ang)


	var x_old := int(self.x)
	# var y_old := int(self.y)
	var z_old := int(self.z)

	self.z = FixedInt.mul(c, z_old) - FixedInt.mul(s, x_old)
	self.x = FixedInt.mul(s, z_old) + FixedInt.mul(c, x_old)

	return self

func normalized() -> FixedVector3:
	var v := FixedVector3.new(self.x, self.y, self.z)
	v.normalize()
	return v

# based on snopek games' SGPysics2D implementation, translated into 3d
func normalize():
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

			var lgth := FixedVector3.new(
					x_big, 
					y_big, 
					z_big
				).length()

			if lgth != 0:
				self.x = FixedInt.div(x_big, lgth)
				self.y = FixedInt.div(y_big, lgth)
				self.z = FixedInt.div(z_big, lgth)

	else:
		var lgth = self.length()
		if lgth != 0:
			self.x = FixedInt.div(self.x, lgth)
			self.y = FixedInt.div(self.y, lgth)
			self.z = FixedInt.div(self.z, lgth)
