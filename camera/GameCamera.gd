extends Node3D
class_name GameCamera

# used when determining starting position of camera
@export_enum("Player 1", "Player 2") var default_pos: int = 0

# used for camera smoothing
@export var smoothing_speed: float = 3.0

@export var camera_node: NodePath
var camera: Camera3D

# nodes used as reference positions for the camera
@onready var cam_ref1: Node3D = $ref1
@onready var cam_ref2: Node3D = $ref2

@onready var p1_screen_pos: Vector2:
	get:
		var world_pos: Vector3 = Vector3()
		var char1: Node = self.get_parent().char_container.get_children()[0]
		if char1 != null:
			world_pos = FixedVector3.to_vec3(char1.collision_body.fixed_position)
		return self.camera.unproject_position(world_pos)

@onready var p2_screen_pos: Vector2:
	get:
		var world_pos: Vector3 = Vector3()
		var char1: Node = self.get_parent().char_container.get_children()[1]
		if char1 != null:
			world_pos = FixedVector3.to_vec3(char1.collision_body.fixed_position)
		return self.camera.unproject_position(world_pos)

@onready var camera_target: Node3D = self.cam_ref1 if self.default_pos == 0 else self.cam_ref2

var camera_last_g_position: Vector3
var camera_last_target: Vector3

func _ready() -> void:
	self.camera = get_node(self.camera_node)
	self.camera.global_position.x = 15.0 if self.default_pos == 0 else -15.0
	
	# self.add_to_group("network_sync")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_input: Variant) -> void:

	self.camera_last_g_position = self.camera.global_position

	var chars: Array[Node] = self.get_parent().char_container.get_children()

	var dist: float = clampf(chars[0].collision_body.global_position
		.distance_to(chars[1].collision_body.global_position) * 1.25, 4.0, 11.0)
	
	self.global_position = (chars[0].collision_body.global_position + chars[1].collision_body.global_position) / 2

	self.look_at(chars[0].collision_body.global_position)

	# assign positions to reference nodes
	self.cam_ref1.position.x = dist
	self.cam_ref2.position.x = -dist
	self.cam_ref1.position.y = self.global_position.y + 1.5
	self.cam_ref2.position.y = self.global_position.y + 1.5

	if abs(self.rotation_degrees.x) < 75:

		if self.camera.global_position.distance_to(self.cam_ref1.global_position) \
			<= self.camera.global_position.distance_to(self.cam_ref2.global_position):
			self.camera.global_position = \
				lerp(self.camera.global_position, self.cam_ref1.global_position, self.smoothing_speed * SyncManager.tick_time)
		else:
			self.camera.global_position = \
				lerp(self.camera.global_position, self.cam_ref2.global_position, self.smoothing_speed * SyncManager.tick_time)

	else:
		self.camera.global_position = self.camera_last_g_position

	# self.camera.global_rotation = Vector3(0,0,0)
	self.camera.look_at(Vector3(self.global_position.x, self.global_position.y + 1, self.global_position.z))

# needs conversion to fixedint
func get_char_position(char_position: Vector3) -> int:

	var inc_position: Vector2 = self.camera.unproject_position(char_position)

	if inc_position == self.p1_screen_pos:
		if self.p1_screen_pos.x < self.p2_screen_pos.x:
			return 1
		else: return 2
	else:
		if self.p2_screen_pos.x < self.p1_screen_pos.x:
			return 1
		else: return 2

func is_player_airborne() -> bool:
	var chars: Array[Node] = get_parent().get_node("Chars").get_children()
	for i: Fighter in chars:
		if !i.collision_body.is_on_floor(i.floor_height):
			return true
	return false


# func _save_state() -> Dictionary:
# 	return {
# 		"camera_position": self.camera.global_position,
# 		"camera_rotation": self.camera.global_rotation
# 	}

# func _load_state(state:Dictionary) -> void:
# 	self.camera.global_position = state["camera_position"]
# 	self.camera.global_rotation = state["camera_rotation"]