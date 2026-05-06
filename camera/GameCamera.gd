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

var p1_screen_pos: Vector2 = Vector2()
var p2_screen_pos: Vector2 = Vector2()

var fixed_position: FixedVector3 = FixedVector3.new():
	set(val):
		fixed_position = val
		self.set_global_position(FixedVector3.ToVec3(val))
var fixed_rotation: FixedVector3 = FixedVector3.new():
	set(val):
		fixed_rotation = val
		self.set_global_rotation(FixedVector3.ToVec3(val))

var camera_fixed_position: FixedVector3 = FixedVector3.new():
	set(val):
		camera_fixed_position = val
		if val != null:
			self.p1_camera.set_global_position(FixedVector3.ToVec3(val))
			self.p2_camera.position.x = -self.p1_camera.position.x
			self.p2_camera.position.y = self.p1_camera.position.y
			self.p2_camera.position.z = -self.p1_camera.position.z

var camera_last_position: FixedVector3

func _ready() -> void:
	if self.default_pos == 0:
		self.p1_camera.current = true
	else:
		self.p2_camera.current = true

	self.fixed_position = FixedVector3.NewFromVec3(self.global_position)

func _network_preprocess(_input: Variant) -> void: # may need to shove off to c# helper function

	if self.default_pos == 0:
		self.p1_screen_pos = self.p1_camera.unproject_position(
			FixedVector3.ToVec3(self.player_1.collision_body.fixed_position)
			)
		self.p2_screen_pos = self.p1_camera.unproject_position(
			FixedVector3.ToVec3(self.player_2.collision_body.fixed_position)
		)
	else:
		self.p1_screen_pos = self.p2_camera.unproject_position(
			FixedVector3.ToVec3(self.player_1.collision_body.fixed_position)
			)
		self.p2_screen_pos = self.p2_camera.unproject_position(
			FixedVector3.ToVec3(self.player_2.collision_body.fixed_position)
		)

	var dist: int = CameraMath.GetDistanceClamped(
		self.player_1.collision_body.fixed_position,
		self.player_2.collision_body.fixed_position
	)
	if self.swap_sides == -1:
		dist = -dist
	
	self.fixed_position = CameraMath.GetCameraTargetPosition(
		self.player_1.collision_body.fixed_position,
		self.player_2.collision_body.fixed_position
	)

	# rotate self to look at player 1
	self.fixed_rotation = CameraMath.GetCameraTargetRotation(
		self.player_1.collision_body.fixed_position,
		self.fixed_position
	)

	# check if cam_ref needs to be swapped
	if CameraMath.NeedsSideSwap(self.fixed_position, self.cam_ref, self.camera_fixed_position):
		self.swap_sides *= -1

	# assign positions to reference nodes
	self.cam_ref = CameraMath.GetCameraRefPosition(dist, self.fixed_position, self.fixed_rotation.y)

	self.camera_fixed_position = CameraMath.LerpCameraPosition(
		self.camera_fixed_position, 
		self.cam_ref, 
		self.smoothing_speed, 
		SyncManager.tick_time
	)

func _process(_delta: float) -> void:	
	var target: Vector3 = Vector3(self.global_position)
	target.y += 0.75
	self.p1_camera.look_at(target)
	self.p2_camera.look_at(target)

# needs conversion to fixedint
func get_char_position(player: int) -> int:
	if player == 0:
		if self.p1_screen_pos.x < self.p2_screen_pos.x:
			return 2
		return 1
	if self.p2_screen_pos.x < self.p1_screen_pos.x:
		return 2
	return 1

func is_player_airborne() -> bool:
	var chars: Array[Node] = get_parent().get_node("Chars").get_children()
	for i: Fighter in chars:
		if !i.collision_body.is_on_floor(i.floor_height):
			return true
	return false


func _save_state() -> Dictionary:
	return {
		"camera_position": {
			"x": self.camera_fixed_position.x,
			"y": self.camera_fixed_position.y,
			"z": self.camera_fixed_position.z
		},
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
	self.camera_fixed_position = FixedVector3.NewFromInt(
		state.camera_position.x,
		state.camera_position.y,
		state.camera_position.z
	)
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
