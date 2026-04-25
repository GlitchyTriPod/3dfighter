@tool
class_name FEFighterCollisionBody
extends FECollisionShape

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	var rem: int = self.fixed_position.y - self.fixed_sphere_radius
	return rem <= floor_height

func fixed_look_at(target: FixedVector3, axis: FixedVector3 = FixedVector3.UP) -> void:

	var forward: FixedVector3 = FixedVector3.sub(target, self.fixed_position)

	# vvv One that Needs to Fucking Work but Does :)  #-nt- 
	var fixed_lookat_basis: Array = FixedVector3.basis_looking_at(forward, axis, true)
	self.fixed_rotation = FixedVector3.basis_get_euler(fixed_lookat_basis)

	if self.fixed_rotation.x != FixedInt.FIXED_ZERO:
		self.fixed_rotation.x = FixedInt.FIXED_ZERO
	if self.fixed_rotation.z != FixedInt.FIXED_ZERO:
		self.fixed_rotation.z = FixedInt.FIXED_ZERO

func _save_state() -> Dictionary:
	return {
		# "position": {
		# 	"x": self.fixed_position.x,
		# 	"y": self.fixed_position.y,
		# 	"z": self.fixed_position.z
		# },
		# # self.fixed_position,
		# "rotation": {
		# 	"x": self.fixed_rotation.x,
		# 	"y": self.fixed_rotation.y,
		# 	"z": self.fixed_rotation.z
		# },
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
	# self.fixed_position = FixedVector3.new(
	# 	state.position.x,
	# 	state.position.y,
	# 	state.position.z
	# )
	# self.fixed_rotation = FixedVector3.new(
	# 	state.rotation.x,
	# 	state.rotation.y,
	# 	state.rotation.z
	# )
	self.velocity = FixedVector3.new(
		state.velocity.x,
		state.velocity.y,
		state.velocity.z
	)
	self.enabled = state.enabled
	self.fixed_sphere_radius = state.sphere_radius
