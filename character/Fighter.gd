extends Node3D
class_name Fighter

@export var character_name := "Fighter"

@export var disable_control: bool = false
@export var actionable: bool = true

@export var walk_speed: int = 196608
@export var back_walk_speed: int = 196608
@export var side_walk_speed: int = 196608
@export var crouch_walk_speed: int = 114688
@export var dash_strength: int = 196608

@export_enum("1","2") var player = 0

@export var face_opponent: bool= true

# @export var fixed_position := FixedVector3.new()
# @export var fixed_rotation := FixedVector3.new()

var stage: Stage

# tracks basic stances for the fighter -- extend if character has multiple stances
enum STANCE {
	STANDING,
	CROUCHING,
	GROUNDED,
	AIRBORNE,
	WALL,
	F_DASH,
	B_DASH,
	SIDESTEP,
	SIDEWALK,
	RUN,
	JUMP
}
var stance = STANCE.STANDING #:
	# set(val):
	# 	stance = val
	# 	self.stance_label.text = STANCE.keys()[val]

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

# incoming attacks are counter hits if this is TRUE
var counter_hit := true

# velocity imparted on the fighter by the enemy pushing them
var impart_velocity := FixedVector3.new()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var char_controller: CharacterController3D = %CharacterBody3D
@onready var mesh = %Mesh

@onready var input_interpreter = %InputInterpreter

@onready var opponent_position: Vector3:
	get:
		var oppo: Fighter
		for i in get_parent().get_children():
			if i == self:
				continue
			oppo = i
			break
		return oppo.mesh.global_position


@onready var screen_position: String:
	get:
		return get_parent() \
			.get_parent() \
			.get_node("GameCamera") \
			.get_char_position(self.mesh.global_position)

@onready var animation_player: AnimationNodeStateMachinePlayback = %CharacterBody3D/AnimationTree["parameters/playback"]

@onready var grounded:
	get:
		return self.char_controller.is_on_floor(self.stage)

@onready var stance_label: Label3D = %Label3D

func _process(_delta: float):

	_delta = int(_delta * 65536)

	self.stance_label.text = STANCE.keys()[self.stance] + " " + str(self.grounded) 

	if self.disable_control: return

	var inp = self.input_interpreter.read_input()

	self.button_state = inp.button
	self.di_state = inp.di

	face_opponent = true


	var opponent_dir = self.char_controller.position.direction_to(self.opponent_position)


	var neutral = func neutral():
		if self.stance == STANCE.SIDESTEP || (self.stance == STANCE.F_DASH || self.stance == STANCE.B_DASH): 
			return
		self.char_controller.velocity = Vector3(0,0,0)
		face_opponent = false
	
	var handle_dash = func handle_dash(dir: String):
		if dir == "f":
			self.animation_player.travel("f_dash")
			self.char_controller.velocity = (opponent_dir * self.walk_speed) * \
			lerpf(self.dash_strength, 0, self.animation_player.get_current_play_position() / 0.3333)
		else:
			self.animation_player.travel("b_dash")
			self.char_controller.velocity = (opponent_dir * -self.back_walk_speed) * \
				clampf(lerpf(self.dash_strength, 0, \
				self.animation_player.get_current_play_position() / (0.3333*0.66)), 0, self.dash_strength)

	var handle_run = func handle_run():
		if self.char_controller.global_position.distance_to(self.opponent_position) < 1:
			self.animation_player.travel("f_walk")
			return
		self.animation_player.travel("run")
		self.char_controller.velocity = opponent_dir * (self.walk_speed * 2)

	var handle_sidestep = func handle_sidestep(dir: String = "iunno"):
		if dir == "RIGHT" || self.animation_player.get_current_node() == "r_sidestep":
			self.animation_player.travel("r_sidestep")
			self.char_controller.velocity = (opponent_dir.rotated(Vector3.UP, deg_to_rad(-85)) * self.side_walk_speed) * \
				clampf(lerpf(self.dash_strength, 0, \
				self.animation_player.get_current_play_position() / (0.3333*0.66)), 0, self.dash_strength)
		else:
			self.animation_player.travel("l_sidestep")
			self.char_controller.velocity = (opponent_dir.rotated(Vector3.UP, deg_to_rad(85)) * self.side_walk_speed) * \
				clampf(lerpf(self.dash_strength, 0, \
				self.animation_player.get_current_play_position() / (0.3333*0.66)), 0, self.dash_strength)

	var handle_sidewalk = func handle_sidewalk(dir: String= "lol"):
		if dir == "LEFT":
			self.animation_player.travel("l_sidewalk")
			self.char_controller.velocity = opponent_dir.rotated(Vector3.UP, deg_to_rad(85)) * self.side_walk_speed
		else:
			self.animation_player.travel("r_sidewalk")
			self.char_controller.velocity = opponent_dir.rotated(Vector3.UP, deg_to_rad(-85)) * self.side_walk_speed


	# set stance state based on current animation
	match self.animation_player.get_current_node():
		"f_dash":
			self.stance = STANCE.F_DASH
		"b_dash":
			self.stance = STANCE.B_DASH
		"crouching", "crouch_walk":
			self.stance = STANCE.CROUCHING
		"l_sidestep", "r_sidestep":
			self.stance = STANCE.SIDESTEP
		"l_sidewalk", "r_sidewalk":
			self.stance = STANCE.SIDEWALK
		"run":
			self.stance = STANCE.RUN
		"jump_1", "jump_2":
			self.stance = STANCE.JUMP
		_:
			self.stance = STANCE.STANDING

	# Handles movement
	if self.stance == STANCE.JUMP:
		match self.animation_player.get_current_node():
			"jump_2":
				neutral.call()
			"jump_1":
				if self.char_controller.velocity.y <= 0.0 && self.grounded:
					self.char_controller.velocity.y += 6.5

	else:
		match self.di_state:
			DI_STATE.FORWARD:
				if self.stance != STANCE.F_DASH && self.stance != STANCE.RUN:
					self.char_controller.velocity = opponent_dir * self.walk_speed
					var inputs = self.input_interpreter.read_input(3)
					if (inputs[0].frame_count < 2 && \
						inputs[1].di == DI_STATE.NEUTRAL && \
						inputs[1].frame_count <= 5 && \
						inputs[2].di == DI_STATE.FORWARD):
						handle_dash.call("f")
				elif self.stance == STANCE.RUN: 
					handle_run.call()
				else:
					var inputs = self.input_interpreter.read_input(2)
					if (inputs[0].frame_count < 2 && \
						inputs[1].di == DI_STATE.NEUTRAL && \
						inputs[1].frame_count <= 13):
						handle_run.call()
					else:
						handle_dash.call("f")
						
			DI_STATE.BACK:
				if self.stance != STANCE.B_DASH:
					self.char_controller.velocity = opponent_dir * -self.back_walk_speed
					var inputs = self.input_interpreter.read_input(3)
					if inputs[0].frame_count < 2 && \
						inputs[1].di == DI_STATE.NEUTRAL && \
						inputs[1].frame_count <= 5 && \
						inputs[2].di == DI_STATE.BACK:
						handle_dash.call("b")
				else:
					handle_dash.call("b")
						
			DI_STATE.DOWN_FORWARD:
				self.char_controller.velocity = opponent_dir * self.crouch_walk_speed

			DI_STATE.DOWN:
				if self.stance == STANCE.SIDESTEP || self.stance == STANCE.SIDEWALK:
					if self.screen_position == "LEFT" && \
						(self.animation_player.get_current_node() == "r_sidestep" || \
						self.animation_player.get_current_node() == "r_sidewalk"):
						handle_sidewalk.call("RIGHT")
					elif self.screen_position == "RIGHT" && \
						(self.animation_player.get_current_node() == "l_sidestep" || \
						self.animation_player.get_current_node() == "l_sidewalk"):
						handle_sidewalk.call("LEFT")
					else:
						neutral.call()
				else:
					neutral.call()

			DI_STATE.UP:
				if self.stance == STANCE.SIDESTEP || self.stance == STANCE.SIDEWALK:
					if self.screen_position == "LEFT" && \
						(self.animation_player.get_current_node() == "l_sidestep" || \
						self.animation_player.get_current_node() == "l_sidewalk"):
						handle_sidewalk.call("LEFT")
					elif self.screen_position == "RIGHT" && \
						(self.animation_player.get_current_node() == "r_sidestep" || \
						self.animation_player.get_current_node() == "r_sidewalk"):
						handle_sidewalk.call("RIGHT")
					else:
						neutral.call()
				else:
					if inp.frame_count > 2:
						self.animation_player.travel("jump_1")

					neutral.call()

			DI_STATE.UP_FORWARD:
				if self.stance != STANCE.JUMP:
					self.animation_player.travel("jump_1")
					var vel = (opponent_dir * self.walk_speed)
					self.char_controller.velocity = vel
					self.stance = STANCE.JUMP
				else:
					self.char_controller.velocity = opponent_dir * self.walk_speed

			DI_STATE.UP_BACK:
				if self.stance != STANCE.JUMP:
					self.animation_player.travel("jump_1")
					var vel = (opponent_dir * -self.back_walk_speed)
					self.char_controller.velocity = vel
					self.stance = STANCE.JUMP
				else:
					self.char_controller.velocity = opponent_dir * -self.back_walk_speed

			DI_STATE.NEUTRAL:
				var inputs = self.input_interpreter.read_input(2)
				if inputs[0].frame_count < 2 && inputs[1].di == DI_STATE.DOWN && inputs[1].frame_count <= 5:
					# sidestep to direction DOWN points
					if self.screen_position == "LEFT":
						handle_sidestep.call("RIGHT")
					else:
						handle_sidestep.call("LEFT")				
				
				elif inputs[0].frame_count < 2 && inputs[1].di == DI_STATE.UP && inputs[1].frame_count <= 8:
					# sidestep to direction DOWN points
					if self.screen_position == "LEFT":
						handle_sidestep.call("LEFT")
					else:
						handle_sidestep.call("RIGHT")
				
				elif self.stance == STANCE.F_DASH:
					handle_dash.call("f")
				elif self.stance == STANCE.B_DASH:
					handle_dash.call("b")
				elif self.stance == STANCE.RUN:
					handle_run.call()
				elif self.stance == STANCE.SIDESTEP:
					handle_sidestep.call()

				else:
					neutral.call()
			_:
				neutral.call()

	# handle button presses here -- but ignore button presses for right now

	# Add the gravity.
	self.char_controller.velocity.y -= 30 * _delta
	
	# face opponent if necessary
	if self.grounded && face_opponent:
		self.char_controller.look_at(self.opponent_position)

	# add velocity imparted by the oppoenent
	self.char_controller.velocity += self.impart_velocity

	self.impart_velocity = FixedVector3.new()

	# self.char_controller.velocity = self.char_controller.velocity.rotated(Vector3.UP, \
	# 	self.char_controller.global_rotation.y)

	self.char_controller.move_and_slide()


	# impart velocity onto the opponent if pushing them

	# first, check how many collisions were found, if the chape owner is CharacterBody3D, that is the opponent fighter.
	for i in range(0, self.char_controller.get_slide_collision_count()):
		var collision = self.char_controller.get_slide_collision(i).get_collider()
		if collision.name == "CharacterBody3D":
			match self.di_state:
				DI_STATE.FORWARD:
					collision.get_parent().impart_velocity = opponent_dir * (self.walk_speed / 0.75)
				DI_STATE.DOWN_FORWARD:
					collision.get_parent().impart_velocity = opponent_dir * (self.crouch_walk_speed / 0.75)
			break


# takes input information from the InputListener and hands it to the InputInterpreter.
func input(input_data: Array[String]):
	self.input_interpreter.interpret_input(input_data)

# used to set stance information from animationtree advance expressions
func set_stance(inc_stance):
	self.stance = inc_stance
	return true