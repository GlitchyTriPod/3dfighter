extends Node3D
class_name GameCamera

# used when determining starting position of camera
@export_enum("Player 1", "Player 2") var default_pos: int = 0
var swap_sides: int = FixedIntGDConstant.FIXED_ONE

# used for camera smoothing
@export var smoothing_speed: float = 3.0

# @export var camera_node: NodePath
@onready var p1_camera: Camera3D = %P1Camera
@onready var p2_camera: Camera3D = %P2Camera

# nodes used as reference positions for the camera
@onready var cam_ref: FixedVector3 = FixedVector3.new()

var player_1: Fighter
var player_2: Fighter

var p1_screen_pos: int = 1
var p2_screen_pos: int = 2

var fixed_position: FixedVector3 = FixedVector3.new()
var fixed_rotation: FixedVector3 = FixedVector3.new()

var camera_fixed_position: FixedVector3 = FixedVector3.new():
	set(val):
		camera_fixed_position = val
		if val != null:
			self.p1_camera.set_global_position(FixedVector3.ToVec3(val))
			self.p2_camera.position.x = -self.p1_camera.position.x
			self.p2_camera.position.y = self.p1_camera.position.y
			self.p2_camera.position.z = -self.p1_camera.position.z

# might use this in the future for specific animations (grabs?)
var lock_camera: bool = false

func _ready() -> void:
	if self.default_pos == 0:
		self.p1_camera.current = true
	else:
		self.p2_camera.current = true

	self.fixed_position = FixedVector3.NewFromVec3(self.global_position)

func _network_preprocess(_input: Variant) -> void: # may need to shove off to c# helper function

	# if x rotation (pitch) is > 90 deg, players have swapped sides
	if abs(self.fixed_rotation.x) > FixedIntGDConstant.FIXED_PI_DIV_2:
		if self.default_pos == 0:
			self.p1_screen_pos = 1
			self.p2_screen_pos = 2
		else:
			self.p1_screen_pos = 2
			self.p2_screen_pos = 1
	else:
		if self.default_pos == 0:
			self.p1_screen_pos = 2
			self.p2_screen_pos = 1
		else:
			self.p1_screen_pos = 1
			self.p2_screen_pos = 2
	
	var values: Array[FixedVector3] = CameraMath.GetCameraRefPosition(
		self.player_1.collision_body.fixed_position,
		self.player_2.collision_body.fixed_position,
		self.default_pos != 0
	) 

	self.fixed_position = values[0]
	self.fixed_rotation = values[1]
	self.cam_ref = values[2]


	self.camera_fixed_position = CameraMath.LerpCameraPosition(
		self.camera_fixed_position, 
		self.cam_ref,
		self.smoothing_speed, 
		SyncManager.tick_time
	)

func _process(_delta: float) -> void:	
	var target: Vector3 = FixedVector3.ToVec3(self.fixed_position) 
	target.y += 0.6
	self.p1_camera.look_at(target)
	self.p2_camera.look_at(target)


func get_char_position(player: int) -> int:
	if player == 0:
		return self.p1_screen_pos
	return self.p2_screen_pos

func is_player_airborne() -> bool:
	var chars: Array[Node] = get_parent().get_node("Chars").get_children()
	for i: Fighter in chars:
		if !i.collision_body.is_on_floor(i.floor_height):
			return true
	return false


func _save_state() -> Dictionary:
	return {
		"position": {
			"x": self.fixed_position.x,
			"y": self.fixed_position.y,
			"z": self.fixed_position.z
		},
		"rotation": {
			"x": self.fixed_rotation.x,
			"y": self.fixed_rotation.y,
			"z": self.fixed_rotation.z
		}
	}

func _load_state(state:Dictionary) -> void:
	self.fixed_position = FixedVector3.NewFromInt(
		state.position.x,
		state.position.y,
		state.position.z
	)
	self.fixed_rotation = FixedVector3.NewFromInt(
		state.rotation.x,
		state.rotation.y,
		state.rotation.z
	)
