@tool
extends Resource
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

var fixed_sphere_radius: int = FixedIntGDConstant.FIXED_HALF

var body_part: int = BODY_PART.NONE

var is_hitbox: bool = false

# used to detect individual hit instances in multi-hit moves
var hitbox_attack_index: int = -1
var hitbox_attack_name: String = ""

var fixed_position: FixedVector3
var fixed_rotation: FixedVector3

var final_position: FixedVector3

var enabled: bool = false

static func create_from_data(data: Variant) -> FECollisionData:
	var col_data: FECollisionData = FECollisionData.new()
	col_data.fixed_sphere_radius = data["radius"]
	if data.has("is_hitbox"):
		col_data.is_hitbox = data["is_hitbox"]
	if data.has("body_part"):
		col_data.body_part = data["body_part"]
	if data.has("animation_name"):
		col_data.hitbox_attack_name = data["animation_name"]
	col_data.fixed_position = data["position"]
	col_data.enabled = true

	return col_data

static func create_from_arr(data_arr: Array) -> Array[FECollisionData]:
	var ret_arr: Array[FECollisionData] = []
	for i: Variant in data_arr:
		ret_arr.append(FECollisionData.create_from_data(i))
	return ret_arr

func fixed_is_overlapping_with(inc_shape: FECollisionData) -> Variant:
	var combined_radius: int = FixedInt.Mul(
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius), 
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius)
	)
	var dist: int = self.final_position.DistanceSquaredTo(inc_shape.final_position)
	if dist < combined_radius:
		return FixedInt.Sqrt64(combined_radius - dist)
	return false
