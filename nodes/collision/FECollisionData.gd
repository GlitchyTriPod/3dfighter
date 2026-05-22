@tool
extends WeakRef
class_name FECollisionData

enum BODY_PART {
	NONE,
	HEAD,
	TORSO,
	WAIST,
	ARM_L,
	ARM_R,
	HAND_L,
	HAND_R,
	LEG_L,
	LEG_R,
	FOOT_L,
	FOOT_R
}

enum ATTACK_HEIGHT {
	HIGH,
	MEDIUM,
	LOW,
	MEDIUM_SPECIAL,
	LOW_SPECIAL
}

var fixed_sphere_radius: int = FixedIntGDConstant.FIXED_HALF

var body_part: int = BODY_PART.NONE

var is_hitbox: bool = false

# used to detect individual hit instances in multi-hit moves
var hitbox_attack_index: int = -1
var hitbox_attack_name: StringName = &""
var attack_height: int = ATTACK_HEIGHT.HIGH

var is_punch: bool = false
var is_kick: bool = false
var is_grab: bool = false
var unblockable: bool = false
var hits_grounded: bool = false

var fixed_position: FixedVector3 = FixedVector3.new()
var fixed_rotation: FixedVector3 = FixedVector3.new()

var final_position: FixedVector3

var enabled: bool = false

static var _pool: Array[FECollisionData] = []

static func pool_get() -> FECollisionData:
	if _pool.is_empty():
		return FECollisionData.new()
	return _pool.pop_back()

static func pool_return(data: FECollisionData) -> void:
	data.reset()
	_pool.append(data)

static func pool_return_arr(data_arr: Array[FECollisionData]) -> void:
	for i: FECollisionData in data_arr:
		pool_return(i)

static func empty_pool() -> void:
	_pool.clear()

static func create_from_data(data: Dictionary) -> FECollisionData:
	var col_data: FECollisionData = pool_get()
	col_data.fixed_sphere_radius = data[&"radius"]
	if data.has(&"is_hitbox"):
		col_data.is_hitbox = data[&"is_hitbox"]
	if data.has(&"body_part"):
		col_data.body_part = data[&"body_part"]
	if data.has(&"animation_name"):
		col_data.hitbox_attack_name = data[&"animation_name"]
	if data.has(&"attack_height"):
		col_data.attack_height = data[&"attack_height"]
	if data.has(&"is_punch"):
		col_data.is_punch = data[&"is_punch"]
	if data.has(&"is_kick"):
		col_data.is_kick = data[&"is_kick"]
	if data.has(&"unblockable"):
		col_data.unblockable = data[&"unblockable"]
	if data.has(&"hits_grounded"):
		col_data.hits_grounded = data[&"hits_grounded"]
	col_data.fixed_position = data[&"position"]
	col_data.enabled = true

	return col_data

static func create_from_arr(data_arr: Array[Dictionary]) -> Array[FECollisionData]:
	var ret_arr: Array[FECollisionData] = []
	for i: Dictionary in data_arr:
		ret_arr.append(FECollisionData.create_from_data(i))
	return ret_arr

func reset() -> void:
	self.fixed_sphere_radius = fixed_sphere_radius
	self.body_part = body_part
	self.is_hitbox = is_hitbox
	self.hitbox_attack_name = hitbox_attack_name
	self.hitbox_attack_index = hitbox_attack_index
	self.attack_height = ATTACK_HEIGHT.HIGH
	self.fixed_position = null
	self.fixed_rotation = null
	self.enabled = false
	self.final_position = null

func fixed_is_overlapping_with(inc_shape: FECollisionData) -> int:
	var combined_radius: int = FixedInt.Mul(
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius), 
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius)
	)
	var dist: int = self.final_position.DistanceSquaredTo(inc_shape.final_position)
	if dist < combined_radius:
		return FixedInt.Sqrt64(combined_radius - dist)
	return 0
