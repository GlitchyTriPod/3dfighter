extends Node3D
class_name GameCamera

# used when determining starting position of camera
@export_enum("Player 1", "Player 2") var default_pos = 0

# used for camera smoothing
@export var smoothing_speed: float = 1.0

@onready var camera = $Camera3D

# nodes used as reference positions for the camera
@onready var cam_ref1: Node3D = $ref1
@onready var cam_ref2: Node3D = $ref2

@onready var p1_screen_pos: Vector2:
	get:
		var world_pos = self.get_parent().char_container.get_children()[0].mesh.global_position
		return self.camera.unproject_position(world_pos)

@onready var p2_screen_pos: Vector2:
	get:
		var world_pos = self.get_parent().char_container.get_children()[1].mesh.global_position
		return self.camera.unproject_position(world_pos)

@onready var camera_target = self.cam_ref1 if self.default_pos == 0 else self.cam_ref2

var camera_last_g_position: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):

	self.camera_last_g_position = self.camera.global_position

	var chars = self.get_parent().char_container.get_children()

	var dist = chars[0].mesh.global_position.distance_to(chars[1].mesh.global_position) * 1.25

	if dist < 4.0:
		dist = 4.0
	elif dist > 11:
		dist = 11
	
	self.global_position = (chars[0].mesh.global_position + chars[1].mesh.global_position) / 2

	self.look_at(chars[0].mesh.global_position)
	# self.rotation.x = 0 # we do not want the camera's parent to rotate vertically
	# self.rotation.z = 0

	# assign positions to reference nodes
	self.cam_ref1.position.x = dist
	self.cam_ref2.position.x = -dist
	self.cam_ref1.position.y = self.global_position.y + 1.5
	self.cam_ref2.position.y = self.global_position.y + 1.5

	if abs(self.rotation_degrees.x) < 75:

		# if abs(self.rotation_degrees.x) > 90.0 || abs(self.rotation_degrees.z) > 90.0:
		# 	if self.camera_target == self.cam_ref1:
		# 		self.camera_target = self.cam_ref2
		# 	else:
		# 		self.camera_target = self.cam_ref1

		if self.camera.global_position.distance_to(self.cam_ref1.global_position) \
			< self.camera.global_position.distance_to(self.cam_ref2.global_position):
			self.camera.global_position = \
				lerp(self.camera.global_position, self.cam_ref1.global_position, self.smoothing_speed * _delta)
		else:
			self.camera.global_position = \
				lerp(self.camera.global_position, self.cam_ref2.global_position, self.smoothing_speed * _delta)

		# self.camera.global_position = \
		# 		lerp( \
		# 			self.camera.global_position, \
		# 			self.camera_target.global_position, \
		# 			self.smoothing_speed * _delta \
		# 			)
	else:
		self.camera.global_position = self.camera_last_g_position

	self.camera.global_rotation = Vector3(0,0,0)
	self.camera.look_at(Vector3(self.global_position.x, self.global_position.y +1.2, self.global_position.z))


	pass

func get_char_position(char_position: Vector3):

	var inc_position: Vector2 = self.camera.unproject_position(char_position)

	if inc_position == self.p1_screen_pos:
		if self.p1_screen_pos.x < self.p2_screen_pos.x:
			return "LEFT"
		else: return "RIGHT"
	else:
		if self.p2_screen_pos.x < self.p1_screen_pos.x:
			return "LEFT"
		else: return "RIGHT"



func is_player_airborne():
	# get:
		var chars = get_parent().get_node("Chars").get_children()
		for i in chars:
			if !i.char_controller.is_on_floor():
				return true
		return false
