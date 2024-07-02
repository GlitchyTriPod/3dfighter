extends Node3D
class_name GameCamera

# used when determining starting position of camera
@export_enum("Player 1", "Player 2") var default_pos := 0

# used for camera smoothing
@export var smoothing_speed: float = 1.0

@export var camera_node: NodePath
var camera: Camera3D

# nodes used as reference positions for the camera
@onready var cam_ref1: Node3D = $ref1
@onready var cam_ref2: Node3D = $ref2

@onready var p1_screen_pos: Vector2:
	get:
		var world_pos = Vector2()
		var char1 = self.get_parent().char_container.get_children()[0]
		if char1 != null:
			world_pos = char1.mesh.global_position
		return self.camera.unproject_position(world_pos)

@onready var p2_screen_pos: Vector2:
	get:
		var world_pos = Vector2()
		var char1 = self.get_parent().char_container.get_children()[1]
		if char1 != null:
			world_pos = char1.mesh.global_position
		return self.camera.unproject_position(world_pos)

@onready var camera_target = self.cam_ref1 if self.default_pos == 0 else self.cam_ref2

var camera_last_g_position: Vector3
var camera_last_target: Vector3

func _ready():
	self.camera = get_node(self.camera_node)
	self.camera.global_position.x = 15.0 if self.default_pos == 0 else -15.0
	# pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):

	self.camera_last_g_position = self.camera.global_position

	var chars = self.get_parent().char_container.get_children()

	var dist = clampf(chars[0].char_controller.collision_body.global_position
		.distance_to(chars[1].char_controller.collision_body.global_position) * 1.25, 4.0, 11.0)
	
	self.global_position = (chars[0].char_controller.collision_body.global_position + chars[1].char_controller.collision_body.global_position) / 2

	self.look_at(chars[0].char_controller.collision_body.global_position)

	# assign positions to reference nodes
	self.cam_ref1.position.x = dist
	self.cam_ref2.position.x = -dist
	self.cam_ref1.position.y = self.global_position.y + 0.5
	self.cam_ref2.position.y = self.global_position.y + 0.5

	if abs(self.rotation_degrees.x) < 75:

		if self.camera.global_position.distance_to(self.cam_ref1.global_position) \
			<= self.camera.global_position.distance_to(self.cam_ref2.global_position):
			self.camera.global_position = \
				lerp(self.camera.global_position, self.cam_ref1.global_position, self.smoothing_speed * _delta)
		else:
			self.camera.global_position = \
				lerp(self.camera.global_position, self.cam_ref2.global_position, self.smoothing_speed * _delta)

	else:
		self.camera.global_position = self.camera_last_g_position

	self.camera.global_rotation = Vector3(0,0,0)
	self.camera.look_at(Vector3(self.global_position.x, self.global_position.y + 0.5, self.global_position.z))

func get_char_position(char_position: Vector3):

	var inc_position: Vector2 = self.camera.unproject_position(char_position)

	if inc_position == self.p1_screen_pos:
		if self.p1_screen_pos.x < self.p2_screen_pos.x:
			return "RIGHT"
		else: return "LEFT"
	else:
		if self.p2_screen_pos.x < self.p1_screen_pos.x:
			return "RIGHT"
		else: return "LEFT"

func is_player_airborne():
	# get:
		var chars = get_parent().get_node("Chars").get_children()
		for i in chars:
			if !i.char_controller.is_on_floor():
				return true
		return false
