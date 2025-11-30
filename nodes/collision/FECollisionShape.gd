@tool
class_name FECollisionShape
extends ShapeCast3D

# Radius of the sphere. use this instead of scale.
@export var fixed_sphere_radius := FixedInt.FIXED_HALF :
	set(val):
		fixed_sphere_radius = val
		# if Engine.is_editor_hint():
		var sph = SphereShape3D.new()
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
	) var body_part := 0

@export var is_hitbox: bool = false

var hitbox_attack_index: int = -1
var hitbox_attack_name: String = ""

var velocity := FixedVector3.new()

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
func _ready():
	self.target_position = Vector3(0,0,0)
	if Engine.is_editor_hint():
		if self.shape == null:
			self.shape = SphereShape3D.new()
		else:
			self.shape = self.shape.duplicate()
		self.debug_shape_custom_color = Color.WHITE
		self.set_collision_mask_value(1, false)
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

# called every frame, only useful for visualization
func _process(_delta):
	if !Engine.is_editor_hint():
		self.visible = self.enabled

# Returns false if shapes are not overlapping. returns overlap distance if they are.
func fixed_is_overlapping_with(inc_shape: FECollisionShape) -> Variant:
	var combined_radius := FixedInt.mul(
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius), 
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius)
	)
	var dist := self.fixed_position.distance_squared_to(inc_shape.fixed_position)
	if dist < combined_radius:
		return FixedInt.sqrt_64(combined_radius - dist)
	return false
