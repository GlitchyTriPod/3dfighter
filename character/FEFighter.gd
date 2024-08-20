@tool
extends Node3D
class_name FEFighter

@export var character_name := "Fighter"

@export_enum("1", "2") var player = 0

@export var states := {
	"crouching": false,
	"rising": false,
	"airborne": false,
	"grounded": false,
	"wall": false,
	"running": false,
	"counterhit": false,
	"invincible": false,
	"invisible": false,
	"actionable": true,
	"face_opponent": false,
}

var stance := "standing"

enum DI_STATE {
	NEUTRAL,
	UP,
	UP_FORWARD,
	FORWARD,
	DOWN_FORWARD,
	DOWN,
	DOWN_BACK,
	BACK,
	UP_BACK
}
# tracks the current direction that the player is holding
var di_state = DI_STATE.NEUTRAL

enum BUTTON_STATE {
	NONE,
	P,
	K,
	A,
	PK,
	PA,
	KA,
	PKA
}
# tracks the buttons that the player is pressing/holding down
var button_state = BUTTON_STATE.NONE

var stage: Stage

var is_on_ground: bool:
	get:
		return self.collision_body.is_on_floor(self.stage.floor_height)

var opponent_position: FixedVector3:
	get:
		var oppo: FEFighter
		for i in get_parent().get_children():
			if i == self:
				continue
			oppo = i
			break
		if oppo.collision_body == null:
			return FixedVector3.new()
		return oppo.fixed_position

var screen_position: String:
	get:
		return get_parent() \
			.get_parent() \
			.get_node("GameCamera") \
			.get_char_position( \
				self.collision_body.position if \
					self.collision_body != null else self.global_position
			)

var tracking := Vector2(0,0)

var velocity := FixedVector3.new()

var fixed_position: FixedVector3:
	set(val):
		fixed_position = val
		self.global_position = FixedVector3.to_vec3(val)
	get:
		return FixedVector3.from_vec3(self.global_position)

var fixed_rotation: FixedVector3:
	set(val):
		fixed_rotation = val
		self.global_rotation = FixedVector3.to_vec3(val)
	get:
		return FixedVector3.from_vec3(self.global_rotation)

@onready var anim_player: AnimationNodeStateMachinePlayback = %AnimationTree["parameters/playback"]
@onready var collision_body: FEFighterCollisionBody = %CollisionBody
@onready var input_interpreter: InputInterpreter = %InputInterpreter

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		%AnimationTree.callback_mode_process = 1
	else:
		%RootMotionView.visible = false
		%AnimationTree.callback_mode_process = 2
	# pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	if Engine.is_editor_hint():
		return

	var delta_int = int(_delta * 65536)
	self.velocity = FixedVector3.new()

	# --detect if player is in contact with enemy hitbox HERE--

	if !self.states["actionable"]: # if player is not actionable they are stuck in a currently playing animation
		return					   # and are unable to cancel.
	
	var inp = self.input_interpreter.read_input()

	self.button_state = inp[0].button
	self.di_state = inp[0].di

	var opponent_dir: FixedVector3
	if self.collision_body == null:
		opponent_dir = FixedVector3.new()
	else:
		opponent_dir = self.collision_body.fixed_position.direction_to(self.opponent_position)

	var next_animation := ""

	# check for standard movement
	next_animation = process_base_movement(opponent_dir)

	# check for character-specific stances

	# check for command/button inputs
	var cmd = process_command_inputs(delta_int)
	if cmd != "":
		next_animation = cmd

	self.anim_player.travel(next_animation)

	%AnimationTree.advance(_delta)

	handle_movement_animation_driven(delta_int)

func process_base_movement(_opponent_dir: FixedVector3) -> String:
	var current_anim = self.anim_player.get_current_node()

	var inputs := self.input_interpreter.read_input(3)

	# handler functions for various types of movement

	var return_val := "neutral"

	var neutral_input = func():
		match self.di_state:
			DI_STATE.DOWN || \
			DI_STATE.DOWN_BACK:
				return "BaseMovement/crouching"
			_:
				return "BaseMovement/standing"

	# checking current animation state to determine which movement option the player is using
	# handle mid-jump animations (still actionable, so it wouldnt get caught earlier)
	if current_anim.contains("jump"):
		match current_anim:
			"BaseMovement/jump_2":
				return_val = neutral_input.call()
			"BaseMovement/jump_1":
				if self.velocity.y <= 0 && self.is_on_ground: # idk if this is really necessary
					self.velocity.y += 425984

	else:
		match self.di_state:
			DI_STATE.NEUTRAL:
				if current_anim.contains("dash") || \
					current_anim.contains("run"): # if dashing or running, ignore neutral input
					return_val = current_anim	  # and continue animation
				else:
					return_val = neutral_input.call()

			DI_STATE.FORWARD:
				if current_anim == "BaseMovement/f_dash":
					return_val = current_anim
				else:
					return_val = "BaseMovement/f_walk"

			DI_STATE.BACK:
				if current_anim == "BaseMovement/b_dash":
					return_val = current_anim
				else:
					return_val = "BaseMovement/b_walk"

			DI_STATE.UP:
				if current_anim.contains("side"):
					if self.screen_position == "LEFT" && \
						(current_anim == "BaseMovement/l_sidestep" || \
						current_anim == "BaseMovement/l_sidewalk"):
						return_val = "BaseMovement/l_sidewalk"
					elif self.screen_position == "RIGHT" && \
						(current_anim == "BaseMovement/r_sidestep" || \
						current_anim == "BaseMovement/r_sidewalk"):
						return_val = "BaseMovement/r_sidewalk"
					else:
						return_val = neutral_input.call()
						
				else:
					if inputs[0].frame_count > 2:
						return_val = "BaseMovement/jump_1"					
					else:
						return_val = neutral_input.call()

			DI_STATE.UP_BACK:
				if !current_anim.contains("jump"): # maybe something with velocity manipulation????
					return_val = "BaseMovement/jump_1"

			DI_STATE.UP_FORWARD:
				if !current_anim.contains("jump"): # maybe something with velocity manipulation????
					return_val = "BaseMovement/jump_1"

			DI_STATE.DOWN:
				if current_anim.contains("side"):
					if self.screen_position == "LEFT" && \
						(current_anim == "BaseMovement/r_sidestep" || \
						current_anim == "BaseMovement/r_sidewalk"):
						return_val = "BaseMovement/r_sidewalk"
					elif self.screen_position == "RIGHT" && \
						(current_anim == "BaseMovement/l_sidestep" || \
						current_anim == "BaseMovement/l_sidewalk"):
						return_val = "BaseMovement/l_sidewalk"
					else:
						return_val = neutral_input.call()
						
				else:
					return_val = neutral_input.call()

			DI_STATE.DOWN_BACK:
				return_val = neutral_input.call()

			DI_STATE.DOWN_FORWARD:
				return_val = "BaseMovement/crouch_walk"

	return return_val

func handle_movement_animation_driven(delta: int):

	# var tree : AnimationTree = %AnimationTree

	# var root_motion = tree.get_root_motion_position()

	# var root_position_delta := FixedVector3.from_vec3(%AnimationTree.get_root_motion_position())

	# self.velocity =FixedVector3.vec_mul(self.fixed_rotation.normalized(), root_position_delta)

	var curr_rotation = self.transform.basis.get_rotation_quaternion()

	self.velocity = FixedVector3.div(
		FixedVector3.from_vec3(
				curr_rotation * %AnimationTree.get_root_motion_position()
		), delta)

	### 
	# For time being, only position is animation driven.
	# This may change if i decide to implement moves that end with player in back-turn.
	###
	# var root_rotation_delta = %AnimationTree.get_root_motion_rotation()

	collide_and_slide(delta)

func process_command_inputs(_delta: int) -> String:

	# dashing
	# sidestepping
	# attacks

	return ""

# takes input information from the InputListener and hands it to the InputInterpreter.
func input(input_data: Array[String]):
	self.input_interpreter.interpret_input(input_data)

func collide_and_slide(delta: int):

	# TODO: Collision with walls

	var new_position: FixedVector3 = self.fixed_position


	new_position.x += FixedInt.mul(self.velocity.x, delta)
	new_position.y += FixedInt.mul(self.velocity.y, delta)
	new_position.z += FixedInt.mul(self.velocity.z, delta)

	var oppo_collision_body : FEFighterCollisionBody = get_tree().get_nodes_in_group(
		"Player2MainCollisionBody" if self.player == 1 \
		else "Player1MainCollisionBody"
	)[0] # this group should never be empty, and should only have 1 member

	var overlap = self.collision_body.fixed_is_overlapping_with(oppo_collision_body)
	
	if overlap is int:
		var change := FixedVector3.mul(
			self.fixed_position.direction_to(oppo_collision_body.fixed_position),
			FixedInt.div(overlap, FixedInt.FIXED_TWO)
		)

		new_position.x -= change.x
		# new_position.y -= change.y
		new_position.z -= change.z
	
	if self.player == 0:
		print(self.velocity.x," ", self.velocity.y," ", self.velocity.z)

	self.position = FixedVector3.to_vec3(new_position)
