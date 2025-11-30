@tool
class_name FEFighterCollisionBody
extends FECollisionShape

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	self.remove_from_group("Player1MiscHurtbox")
	self.remove_from_group("Player2MiscHurtbox")

	if self.get_parent().player == 0:
		self.add_to_group("Player1MainCollisionBody")
	else:
		self.add_to_group("Player2MainCollisionBody")

func is_on_floor(floor_height: int) -> bool:
	var rem = self.fixed_position.y - self.fixed_sphere_radius
	return rem <= floor_height

func fixed_look_at(target: FixedVector3, axis: Vector3 = Vector3.UP):

	var origin := FixedVector3.from_vec3(self.global_transform.origin)

	var forward := FixedVector3.sub(target, origin)
	var lookat_basis := FixedVector3.basis_looking_at(forward, axis, true)

	var original_scale = self.scale

	self.global_transform = Transform3D(lookat_basis, FixedVector3.to_vec3(origin))

	self.fixed_rotation.x = FixedInt.FIXED_ZERO
	self.fixed_rotation.z = FixedInt.FIXED_ZERO

	self.scale = original_scale
