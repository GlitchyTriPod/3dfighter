@tool
extends ShapeCast3D
class_name FECollisionShape

# Radius of the sphere. use this instead of scale.
@export var fixed_sphere_radius: int = FixedInt.FIXED_HALF :
	set(val): # <---- VERY BAD PERFORMANCE. GENERATING 3D SHAPE SHOULD NOT BE DONE IN PRODUCTION
		fixed_sphere_radius = val
		var sph: Shape3D = self.shape
		if Engine.is_editor_hint():
			sph = SphereShape3D.new()
		sph.radius = float(val / 65536.0)
		self.shape = sph

@export var shape_owner : NodePath

@export_enum(
	"none",
	"head",
	"torso",
	"waist",
	"arm",
	"hand",
	"leg",
	"foot"
	) var body_part: int = 0

@export var is_hitbox: bool = false

var hitbox_attack_index: int = -1
var hitbox_attack_name: String = ""

var velocity: FixedVector3 = FixedVector3.new()

var fixed_position: FixedVector3:
	get:
		return FixedVector3.from_vec3(self.global_position)
	set(val):
		fixed_position = val
		self.global_position = FixedVector3.to_vec3(val)

var fixed_rotation: FixedVector3:
	get:
		return FixedVector3.from_vec3(self.global_rotation)
	set(val):
		fixed_rotation = val
		self.global_rotation = FixedVector3.to_vec3(val)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.collide_with_areas = false
	self.collide_with_bodies = false

	self.target_position = Vector3(0,0,0)
	if self.shape == null:
		self.shape = SphereShape3D.new()
	else:
		self.shape = self.shape.duplicate()
	self.shape.radius = float(self.fixed_sphere_radius / 65536.0)
	self.debug_shape_custom_color = Color.WHITE
	self.set_collision_mask_value(1, false)

	if Engine.is_editor_hint():
		return
	
	if self.get_parent() is BoneAttachment3D:
		if (get_node(self.shape_owner) as Fighter).player == 0:
			self.add_to_group("Player1MainHurtbox")
		else:
			self.add_to_group("Player2MainHurtbox")
	elif self.is_hitbox:
		if (get_node(self.shape_owner) as Fighter).player == 0:
			self.add_to_group("Player1MiscHitbox")
		else:
			self.add_to_group("Player2MiscHitbox")
	else:
		if (get_node(self.shape_owner) as Fighter).player == 0:
			self.add_to_group("Player1MiscHurtbox")
		else:
			self.add_to_group("Player2MiscHurtbox")

	# self.add_to_group("network_sync")

# called every frame, only useful for visualization
# func _process(_delta):
# 	if !Engine.is_editor_hint():
# 		self.visible = self.enabled

# func _save_state() -> Dictionary:
# 	return {
# 		# "position": {
# 		# 	"x": self.fixed_position.x,
# 		# 	"y": self.fixed_position.y,
# 		# 	"z": self.fixed_position.z
# 		# },
# 		# # self.fixed_position,
# 		# "rotation": {
# 		# 	"x": self.fixed_rotation.x,
# 		# 	"y": self.fixed_rotation.y,
# 		# 	"z": self.fixed_rotation.z
# 		# },
# 		# # "rotation": self.fixed_rotation,
# 		# "velocity": {
# 		# 	"x": self.velocity.x,
# 		# 	"y": self.velocity.y,
# 		# 	"z": self.velocity.z
# 		# },
# 		# # "velocity": self.velocity
# 		"enabled": self.enabled,
# 		# "sphere_radius": self.fixed_sphere_radius
# 	}

# func _load_state(state: Dictionary) -> void:
# 	# self.fixed_position = FixedVector3.new(
# 	# 	state.position.x,
# 	# 	state.position.y,
# 	# 	state.position.z
# 	# )
# 	# self.fixed_rotation = FixedVector3.new(
# 	# 	state.rotation.x,
# 	# 	state.rotation.y,
# 	# 	state.rotation.z
# 	# )
# 	# self.velocity = FixedVector3.new(
# 	# 	state.velocity.x,
# 	# 	state.velocity.y,
# 	# 	state.velocity.z
# 	# )
# 	self.enabled = state.enabled
# 	# self.fixed_sphere_radius = state.sphere_radius

# Returns false if shapes are not overlapping. returns overlap distance if they are.
func fixed_is_overlapping_with(inc_shape: FECollisionShape) -> Variant:
	var combined_radius: int = FixedInt.mul(
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius), 
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius)
	)
	var dist: int = self.fixed_position.distance_squared_to(inc_shape.fixed_position)
	if dist < combined_radius:
		return FixedInt.sqrt_64(combined_radius - dist)
	return false
