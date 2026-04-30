@tool

# This node is used for debugging purposes only, costs too much performance to use online or in production.
extends ShapeCast3D
class_name FECollisionShape

# Radius of the sphere. use this instead of scale.
@export var fixed_sphere_radius: int = FixedIntGDConstant.FIXED_HALF:
	set(val):
		fixed_sphere_radius = val
		if OS.has_feature("show_hitboxes") || Engine.is_editor_hint(): # <---- VERY BAD PERFORMANCE. DEBUGGING + OFFLINE ONLY
			# var sph: Shape3D = self.shape
			self.shape.radius = float(val / 65536.0)
			# self.shape = sph

@export var shape_owner : NodePath

@export_enum(
	"none",
	"head",
	"torso",
	"waist",
	"left arm",
	"right arm",
	"left hand",
	"right hand",
	"left leg",
	"right leg",
	"left foot",
	"right foot"
	) var body_part: int = 0

@export var is_hitbox: bool = false

var hitbox_attack_index: int = -1
var hitbox_attack_name: String = ""

var velocity: FixedVector3 = FixedVector3.new()

@onready var fixed_position: FixedVector3 = FixedVector3.FromVec3(self.global_position):
	set(val):
		fixed_position = val
		self.global_position = FixedVector3.ToVec3(val)

@onready var fixed_rotation: FixedVector3 = FixedVector3.FromVec3(self.global_rotation):
	set(val):
		fixed_rotation = val
		self.global_rotation = FixedVector3.ToVec3(val)

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

	self.debug_shape_custom_color = Color.WHITE if self.is_hitbox == false else Color.MAGENTA
	self.set_collision_mask_value(1, false)

# called every frame, only useful for visualization
func _process(_delta: float) -> void:
	if OS.has_feature("show_hitboxes"):
		self.visible = self.enabled

# Returns false if shapes are not overlapping. returns overlap distance if they are.
func fixed_is_overlapping_with(inc_shape: FECollisionShape) -> Variant:
	var combined_radius: int = FixedInt.Mul(
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius), 
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius)
	)
	var dist: int = self.fixed_position.DistanceSquaredTo(inc_shape.fixed_position)
	if dist < combined_radius:
		return FixedInt.Sqrt64(combined_radius - dist)
	return false

func copy_collision_data(collision_data: FECollisionData) -> void:
	self.enabled = collision_data.enabled
	self.fixed_position = collision_data.fixed_position
	self.fixed_sphere_radius = collision_data.fixed_sphere_radius
	self.hitbox_attack_name = collision_data.hitbox_attack_name
	self.is_hitbox = collision_data.is_hitbox
	if self.is_hitbox:
		self.debug_shape_custom_color = Color.MAGENTA
	else:
		self.debug_shape_custom_color = Color.WHITE