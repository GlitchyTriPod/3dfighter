extends Node3D
class_name GameCamera

# used when determining starting position of camera
@export_enum("Player 1", "Player 2") var default_pos: int = 0

# used for camera smoothing
@export var smoothing_speed: float = 3.0

@export var camera_node: NodePath
var camera: Camera3D

# nodes used as reference positions for the camera
@onready var cam_ref1: FixedVector3 = FixedVector3.new()
@onready var cam_ref2: FixedVector3 = FixedVector3.new()

@onready var p1_screen_pos: Vector2: # bad performance sometimes A LOT MOTHERFUCKER????
	get:
		var world_pos: Vector3 = Vector3()
		var char1: Node = self.get_parent().char_container.get_children()[0]
		if char1 != null:
			world_pos = FixedVector3.ToVec3(char1.collision_body.fixed_position)
		return self.camera.unproject_position(world_pos)

@onready var p2_screen_pos: Vector2:
	get:
		var world_pos: Vector3 = Vector3()
		var char1: Node = self.get_parent().char_container.get_children()[1]
		if char1 != null:
			world_pos = FixedVector3.ToVec3(char1.collision_body.fixed_position)
		return self.camera.unproject_position(world_pos)

# @onready var camera_target: FixedVector3 = self.cam_ref1 if self.default_pos == 0 else self.cam_ref2

var player_1: Fighter
var player_2: Fighter

var fixed_position: FixedVector3 = FixedVector3.new():
	set(val):
		fixed_position = val
		self.global_position = FixedVector3.ToVec3(val)
var fixed_rotation: FixedVector3 = FixedVector3.new():
	set(val):
		fixed_rotation = val
		self.global_rotation = FixedVector3.ToVec3(val)

var camera_fixed_position: FixedVector3 = FixedVector3.new():
	set(val):
		camera_fixed_position = val
		if val != null:
			self.camera.global_position = FixedVector3.ToVec3(val)

var camera_last_position: FixedVector3
var camera_last_target: Vector3

func _ready() -> void:
	self.camera = get_node(self.camera_node)
	self.camera.global_position.x = 15.0 if self.default_pos == 0 else -15.0

	self.fixed_position = FixedVector3.NewFromVec3(self.global_position)
	self.camera_fixed_position = FixedVector3.NewFromVec3(self.camera.global_position)

func _network_preprocess(_input: Variant) -> void: # may need to shove off to c# helper function

	var dist: int = clampi(
		FixedInt.Mul(
			self.player_1.collision_body.fixed_position.DistanceTo(
				self.player_2.collision_body.fixed_position
			), 
			FixedInt.FromFloat(0.75)
		), 
		900, 
		1800
	)
	
	self.fixed_position = FixedVector3.Div(
		FixedVector3.Add(
			self.player_1.collision_body.fixed_position, 
			self.player_2.collision_body.fixed_position
			), FixedIntGDConstant.FIXED_TWO
		)

	# rotate self to look at player 1

	var fwd: FixedVector3 = FixedVector3.Sub(
		self.player_1.collision_body.fixed_position, 
		self.fixed_position
	)

	var lookat_basis: Array = FixedVector3.BasisLookingAt(
		fwd,
		FixedVector3.NewFromInt(0, FixedIntGDConstant.FIXED_ONE, 0),
		true
	)
	self.fixed_rotation = FixedVector3.BasisGetEuler(lookat_basis)

	########

	# assign positions to reference nodes
	self.cam_ref1.x = FixedInt.Lerp(FixedInt.FromInt(4), FixedInt.FromInt(20), FixedInt.Div(dist - 900, 1800))
	self.cam_ref2.x = -cam_ref1.x
	self.cam_ref1.y = self.fixed_position.y + FixedIntGDConstant.FIXED_HALF
	self.cam_ref2.y = self.fixed_position.y + FixedIntGDConstant.FIXED_HALF
	self.cam_ref1.z = 0
	self.cam_ref2.z = 0

	self.cam_ref1 = FixedVector3.Add(
		self.cam_ref1.Rotated(self.fixed_rotation.y),
		FixedVector3.NewFromFixedVec3(self.fixed_position)
	)
	self.cam_ref2 = FixedVector3.Add(
		self.cam_ref2.Rotated(self.fixed_rotation.y),
		FixedVector3.NewFromFixedVec3(self.fixed_position)
	)

	if abs(self.fixed_rotation.x) < FixedInt.FromFloat(1.309): # 75 deg.
		if self.default_pos == 0:
			self.lerp_to_intended_position()
		else:
			self.lerp_to_intended_position(true)
	else:
		self.camera_fixed_position = self.cam_ref2

func lerp_to_intended_position(is_p2_camera: bool = false) -> void:
	if is_p2_camera:
		if self.camera_fixed_position.DistanceSquaredTo(self.cam_ref1) \
				>= self.camera_fixed_position.DistanceSquaredTo(self.cam_ref2):
			self.camera_fixed_position = \
				FixedVector3.Lerp(
					self.camera_fixed_position, 
					self.cam_ref1, 
					FixedInt.Mul(
						FixedInt.FromFloat(self.smoothing_speed),
						FixedInt.FromFloat(SyncManager.tick_time)
					)
				)
		else:
			self.camera_fixed_position = \
				FixedVector3.Lerp(
					self.camera_fixed_position, 
					self.cam_ref2,
					FixedInt.Mul(
						FixedInt.FromFloat(self.smoothing_speed), 
						FixedInt.FromFloat(SyncManager.tick_time)
					)
				)
		return
	if self.camera_fixed_position.DistanceSquaredTo(self.cam_ref1) \
			<= self.camera_fixed_position.DistanceSquaredTo(self.cam_ref2):
		self.camera_fixed_position = \
			FixedVector3.Lerp(
				self.camera_fixed_position, 
				self.cam_ref1, 
				FixedInt.Mul(
					FixedInt.FromFloat(self.smoothing_speed),
					FixedInt.FromFloat(SyncManager.tick_time)
				)
			)
	else:
		self.camera_fixed_position = \
			FixedVector3.Lerp(
				self.camera_fixed_position, 
				self.cam_ref2,
				FixedInt.Mul(
					FixedInt.FromFloat(self.smoothing_speed), 
					FixedInt.FromFloat(SyncManager.tick_time)
				)
			)

func _process(_delta: float) -> void:	
	# self.camera.global_rotation = Vector3(0,0,0)
	var target: FixedVector3 = FixedVector3.NewFromFixedVec3(self.fixed_position)
	target.y += FixedInt.FromFloat(0.75)
	self.camera.look_at(FixedVector3.ToVec3(target))

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