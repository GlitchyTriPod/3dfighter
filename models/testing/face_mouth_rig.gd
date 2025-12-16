@tool
extends Node

@export var enabled := false

@export var eye_textures := []
@export var mouth_textures := []

@export var skeleton : NodePath

@export var eye_value: int = 6
@export var mouth_value: int = 6

var skeleton_node: Skeleton3D
var eye_bone : int
var mouth_bone : int

@onready var eye_mesh : MeshInstance3D = self.get_parent().get_node("char_grp/rig/Skeleton3D/eyes")
@onready var mouth_mesh : MeshInstance3D = self.get_parent().get_node("char_grp/rig/Skeleton3D/mouth")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.skeleton_node = self.get_node(self.skeleton)
	self.eye_bone = self.skeleton_node.find_bone("eyes.x")
	self.mouth_bone = self.skeleton_node.find_bone("mouth.x")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !self.enabled: return

	self.eye_mesh.get_surface_override_material(0).albedo_texture = self.eye_textures[self.eye_value]
	self.mouth_mesh.get_surface_override_material(0).albedo_texture = self.mouth_textures[self.mouth_value]

# 	var eye_pos := clampf(self.skeleton_node.get_bone_pose_position(self.eye_bone).y, 0.0, 0.06)
# 	var mouth_pos := clampf(self.skeleton_node.get_bone_pose_position(self.mouth_bone).y, 0.0, 0.06)

# 	(self.eye_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_texture = \
# 		self.eye_textures[self.get_bone_value(eye_pos)]
# 	(self.mouth_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_texture = \
# 		self.mouth_textures[self.get_bone_value(mouth_pos)]

# func get_bone_value(bone_pos: float) -> int:
# 	return floor(bone_pos * 100.0)

	# var val = bone_pos.y * 100

