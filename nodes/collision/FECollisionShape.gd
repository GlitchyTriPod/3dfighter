@tool
extends ShapeCast3D
class_name FECollisionShape

# Radius of the sphere. use this instead of scale.
@export var fixed_sphere_radius: int = FixedInt.FIXED_HALF:
	set(val):
		fixed_sphere_radius = val
		if OS.has_feature("show_collision_shapes"): # <---- VERY BAD PERFORMANCE. DEBUGGING + OFFLINE ONLY
			# var sph: Shape3D = self.shape
			self.shape.radius = float(val / 65536.0)
			# self.shape = sph

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

@onready var fixed_position: FixedVector3 = FixedVector3.from_vec3(self.global_position):
	set(val):
		fixed_position = val
		self.global_position = FixedVector3.to_vec3(val)

@onready var fixed_rotation: FixedVector3 = FixedVector3.from_vec3(self.global_rotation):
	set(val):
		fixed_rotation = val
		self.global_rotation = FixedVector3.to_vec3(val)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	self.target_position = Vector3(0,0,0)

	if self.shape == null:
		self.shape = SphereShape3D.new()
	else:
		self.shape = self.shape.duplicate()
	self.shape.radius = float(self.fixed_sphere_radius / 65536.0)

	self.collide_with_areas = false
	self.collide_with_bodies = false

	self.debug_shape_custom_color = Color.WHITE if self.is_hitbox == false else Color.YELLOW_GREEN
	self.set_collision_mask_value(1, false)

	if Engine.is_editor_hint():
		return
	

# called every frame, only useful for visualization
func _process(_delta: float) -> void:
	if OS.has_feature("show_collision_shapes"):
		self.visible = self.enabled

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
