@tool
class_name FEFighterCollisionBody
extends FECollisionShape

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	self.debug_shape_custom_color = Color.GREEN
	self.remove_from_group("Player1MiscHurtbox")
	self.remove_from_group("Player2MiscHurtbox")

	if self.get_parent().player == 0:
		self.add_to_group("Player1MainCollisionBody")
	else:
		self.add_to_group("Player2MainCollisionBody")

	self.add_to_group("network_sync")

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

func _save_state() -> Dictionary:
	return {
		"position": {
			"x": self.fixed_position.x,
			"y": self.fixed_position.y,
			"z": self.fixed_position.z
		},
		# self.fixed_position,
		"rotation": {
			"x": self.fixed_rotation.x,
			"y": self.fixed_rotation.y,
			"z": self.fixed_rotation.z
		},
		# "rotation": self.fixed_rotation,
		"velocity": {
			"x": self.velocity.x,
			"y": self.velocity.y,
			"z": self.velocity.z
		},
		# "velocity": self.velocity
		"enabled": self.enabled,
		"sphere_radius": self.fixed_sphere_radius
	}

func _load_state(state: Dictionary) -> void:
	self.fixed_position = FixedVector3.new(
		state.position.x,
		state.position.y,
		state.position.z
	)
	self.fixed_rotation = FixedVector3.new(
		state.rotation.x,
		state.rotation.y,
		state.rotation.z
	)
	self.velocity = FixedVector3.new(
		state.velocity.x,
		state.velocity.y,
		state.velocity.z
	)
	self.enabled = state.enabled
	self.fixed_sphere_radius = state.sphere_radius