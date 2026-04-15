@tool
extends Node3D
class_name Fighter

@export var fighter_name: String = "DUMMY"

# @export_enum("1", "2") 
var player: int = 0

# const state_default: Dictionary = {
# 	"crouching": false,
# 	"rising": false,
# 	"airborne": false,
# 	"grounded": false,
# 	"wall": false,
# 	"running": false,
# 	"counterhit": false,
# 	"invincible": false,
# 	"invisible": false,
# 	"actionable": true,
# 	"face_opponent": false,
# 	"hit_stun": false,
# 	"block_stun": false
# }

var stun_reason: Dictionary = {
	"stun_name": "", # not really sure what im using this for rn im sure its important
	"stun_hit": -1, # used to prevent hit registering multiple times on consecutive frames
	"stun_id": "" # holds the id of the stun animation to be played
}

# var states: Dictionary = state_default.duplicate(true)
var states: Array[String] = []

@export var movelist: FighterMovelist

@export var animation_library: AnimationLibrary

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

var stance: int = STANCE.STANDING

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
var di_state: int = DI_STATE.NEUTRAL

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
var button_state: int = BUTTON_STATE.NONE

var message_bus: FighterMessageBus

var floor_height: int = 0

var is_on_ground: bool:
	get:
		return self.collision_body.is_on_floor(self.floor_height)

var opponent_position: FixedVector3:
	get:
		return self.message_bus.get_oppo_fixed_position(self)

var screen_position: int:
	get:
		return self.message_bus \
			.get_char_position( \
				FixedVector3.to_vec3(self.collision_body.fixed_position if \
					self.collision_body != null else self.collision_body.fixed_position
				)
			)

@onready var collision_body: FEFighterCollisionBody = %CollisionBody

var input_interpreter: InputInterpreter = InputInterpreter.new()

@onready var anim_player: NetworkAnimationPlayer = %NetworkAnimationPlayer

var current_anim_id: String = "0" # Movelist item, NOT animation name
			
var collision_body_offset: Vector3

@onready var misc_hitbox_pool: Array = %MiscHitboxPool.get_children()
@onready var misc_hurtbox_pool: Array = %MiscHurtboxPool.get_children()

var is_focused: bool = false

var is_online: bool = false

signal ready_for_input_process(player: Fighter)

# ======= METHODS =====================

func _ready() -> void:
	if Engine.is_editor_hint():
		self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	else:
		%AddonSpheres.free()

		self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		self.collision_body_offset = self.collision_body.position
		self.collision_body.top_level = true

	get_window().focus_entered.connect(self._on_window_focus_entered)
	get_window().focus_exited.connect(self._on_window_focus_exited)

func _on_window_focus_entered() -> void:
	self.is_focused = true

func _on_window_focus_exited() -> void:
	self.is_focused = false

func get_misc_unused_hitbox() -> Variant:
	for i: FECollisionShape in self.misc_hitbox_pool:
		if !i.enabled:
			return i
	return

# Passes player input onto input interpreter
# func input(player_input: Array[String]):
# 	self.input_interpreter.interpret_input(player_input, self.screen_position)

func _network_process(input: Dictionary) -> void:
	# if !self.process_inputs:
	# 	return
	# input.direction.append_array(input.button)
	self.input_interpreter.interpret_input(input, self.screen_position)
	emit_signal("ready_for_input_process", self)

# preddy sure this is unused now
func _get_local_input() -> Dictionary:
	var player_input : Dictionary = {}

	if !self.is_focused:
		
		return player_input

	var dir: Vector2i = Vector2i(
		int(Input.is_action_pressed("INPUT_LEFT_P" + str(1 if self.is_online else (self.player + 1)))) \
		- int(Input.is_action_pressed("INPUT_RIGHT_P" + str(1 if self.is_online else (self.player + 1)))),
		int(Input.is_action_pressed("INPUT_UP_P" + str(1 if self.is_online else (self.player + 1)))) \
		- int(Input.is_action_pressed("INPUT_DOWN_P" + str(1 if self.is_online else (self.player + 1))))
	)

	if dir != Vector2i.ZERO:
		player_input["input_directional"] = dir

	if Input.is_action_pressed("INPUT_PUNCH_P" + str(1 if self.is_online else (self.player + 1))):
		if !player_input.has("input_button"):
			player_input["input_button"] = {}
		player_input["input_button"]["p"] = true
	if Input.is_action_pressed("INPUT_KICK_P" + str(1 if self.is_online else (self.player + 1))):
		if !player_input.has("input_button"):
			player_input["input_button"] = {}
		player_input["input_button"]["k"] = true
	if Input.is_action_pressed("INPUT_ABILITY_P" + str(1 if self.is_online else (self.player + 1))):
		if !player_input.has("input_button"):
			player_input["input_button"] = {}
		player_input["input_button"]["a"] = true


	return player_input

func _save_state() -> Dictionary:
	return {
		"input_history": self.input_interpreter.input_history.duplicate(),
	}

func _load_state(state: Dictionary) -> void:
	self.input_interpreter.input_history = state.input_history

# 	return {
# 		"position": self.position,
# 		"rotation": self.rotation,
# 		# "states": self.states,
# 		# "stance": self.stance,
# 		# "button_state": self.button_state,
# 		# "di_state": self.di_state
# 	}

# 	self.position = state.position
# 	self.rotation = state.rotation
	# self.states = state.states
	# self.stance = state.stance
	# self.button_state = state.button_state
	# self.di_state = state.di_state
	# self.stun_reason = state.stun_reason
	# self.current_anim_id = state.current_anim
	# self.input_interpreter.input_history = state.input_history

func reset_stun_reason() -> void:
	self.stun_reason = {
		"stun_name": "",
		"stun_hit": -1,
		"stun_id": ""
	}

# checks the current animation id, sets player state based on currently playing animation
func process_animation_data() -> void:
	# vv this should never happen bc an animation should always be present & have state data
	# if self.current_anim_id == "":
	# 	self.states = state_default.duplicate(true) # <-- *may* cause problems later
	# 	return

	# retrieve current anim id
	
	var atk: FighterAnimationData = self.movelist.get_from_id(self.current_anim_id)

	# set states
	var current_frame: int = int(floor(self.anim_player.current_animation_position * 60))
	for state: String in atk.player_states.keys():

		# if self.states.has(state):
		var state_data: Variant = atk.player_states.get(state)
		if current_frame >= state_data.frame_range.start && \
			current_frame < state_data.frame_range.end:
			if self.states.has(state):
				continue
			self.states.append(state)
		else:
			if self.states.has(state):
				self.states.remove_at(self.states.find(state))

# checks current animation for hitboxes & places them into the scene if necessary
func process_animation_hitboxes() -> void:
	# if self.current_anim_id == "":
	# 	return
	
	for i: FECollisionShape in self.misc_hitbox_pool:
		i.enabled = false
		i.hitbox_attack_index = -1
		i.hitbox_attack_name = ""

	var atk: FighterAnimationData = self.movelist.get_from_id(self.current_anim_id)

	#find hitboxes
	var current_frame: int = int(floor(self.anim_player.current_animation_position * 60))
	var hitbox_data: Dictionary
	var index: int
	if atk.hitbox_data.has("shapes"):
		for h_b: Dictionary in atk.hitbox_data["shapes"]:
			if !(current_frame >= h_b.frame_range.start && current_frame < h_b.frame_range.end):
				continue
			hitbox_data = h_b
			index = atk.hitbox_data["shapes"].find(h_b)
			break
	
	if hitbox_data == null:
		return

	for shape: Dictionary in hitbox_data.shapes:
		var hitbox: FECollisionShape = self.get_misc_unused_hitbox() # as FECollisionShape
		if hitbox == null:
			break
		hitbox.hitbox_attack_index = index
		hitbox.hitbox_attack_name = atk.animation_name
		hitbox.position = FixedVector3.to_vec3(shape.position)
		hitbox.fixed_sphere_radius = shape.radius
		hitbox.enabled = true

# checks if current fighter is intersecting with an enemy hitbox
func process_hitbox_intersection() -> void:

	var enemy_hitboxes: Array = get_tree().get_nodes_in_group(
		"Player1MiscHitbox" if self.player != 0 else "Player2MiscHitbox"
	)

	var self_hurtboxes: Array = get_tree().get_nodes_in_group(
		"Player1MainHurtbox" if self.player == 0 else "Player2MainHurtbox"
	) + self.misc_hurtbox_pool

	for hitbox: FECollisionShape in enemy_hitboxes:
		if !hitbox.enabled || \
			((hitbox.hitbox_attack_index == self.stun_reason.stun_hit && \
			hitbox.hitbox_attack_name == self.stun_reason.stun_name)): 
			continue

		# Check for early break conditions here (high atk vs. crouching opp., etc.)

		for hurtbox: FECollisionShape in self_hurtboxes:
			if !hurtbox.enabled:
				continue
			
			if hurtbox.fixed_is_overlapping_with(hitbox) is int:
				# incoming hit detected!
				self.process_hit(
					hitbox.hitbox_attack_index, 
					hitbox.hitbox_attack_name, 
					self.message_bus.get_oppo_current_animation_id(self)
				)
				# if self.current_anim_id != "":
				# 	self.current_anim_id = ""
				break

func process_hit(attack_index: int, animation_name: String, animation_id: String) -> void:
	var enemy_anim_data: FighterAnimationData = self.message_bus.get_oppo_current_animation_data(self, animation_id)

	# TODO: Need to determine if this is a block or hit stun, currently only hitstun enabled
	var stun_move: String = self.movelist.get_default_anim_id_from_name(enemy_anim_data.hit_animation)

	self.stun_reason.stun_hit = attack_index
	self.stun_reason.stun_name = animation_name
	self.stun_reason.stun_id = stun_move

# processes movement for player
func process_movement(delta: int) -> void: # could use some optimizing

	# check if fighter needs to be placed in a stun animation
	if self.stun_reason.stun_id != "":
		self.set_animation_order(self.movelist.get_from_id(self.stun_reason.stun_id))
		self.reset_stun_reason()

	# region old
	# check HERE if player needs to be put in stun state
	# if self.stun_reason.stun_id != "":
	# 	# self.states["actionable"] = false
	# 	self.states.remove_at(self.states.find("actionable"))
	# 	if !self.anim_player.current_animation.begins_with("hit"):
	# 		var atk_data: FighterAnimationData = self.message_bus.get_oppo_current_animation_data(self, self.stun_reason.stun_id)

	# 		if self.anim_player.current_animation != atk_data.hitbox_data[self.stun_reason.stun_hit].hit_anim:
	# 			self.anim_player.play("AnimLibrary_test_newrig/" + atk_data.hitbox_data[self.stun_reason.stun_hit].hit_anim)

	# 	else: # will neeed to be deleted later
	# 		if self.anim_player.current_animation_position * 60 >= 23: # <-- WAIT I CAN CONTROL THE STUN LENGTH WITH THIS YESSSS
	# 			# self.states["actionable"] = true
	# 			self.states.remove_at(self.states.find("actionable"))
	# 			self.anim_player.play("AnimLibrary_test_newrig/idle_standing_BAKED")

	# 			self.stun_reason = {
	# 				"stun_name": "",
	# 				"stun_hit": -1,
	# 				"stun_id": ""
				# }
	# endregion

	# if player is not actionable they cannot cancel current animation; keep playing
	if !self.states.has("actionable"):
		# if self.anim_player.is_playing():
		# 	self.anim_player.advance(SyncManager.tick_time )#float(delta / 65536.0))
		self.process_root_motion(delta)
		return

	var inp: Array = self.input_interpreter.read_input()
	if inp.size() == 0 || inp[0] == null:
		return

	# determine animation to play
	var next_move: FighterAnimationData = self.get_move_from_input()

	if next_move.animation_name != self.anim_player.current_animation:
		self.set_animation_order(next_move)

	# if next_anim != self.anim_player.current_animation && next_anim != "_BAKED":
	# 	self.anim_player.play("AnimLibrary_test_newrig/" + next_anim)

	# self.set_stance_state()

	# self.anim_player.advance(SyncManager.tick_time) # <-- maybe this should be 1 frame length??? (1/60th sec?)

	self.process_root_motion(delta)

func set_animation_order(atk_data: FighterAnimationData) -> void:
	if !atk_data.recovery_ref.is_empty():
			self.anim_player.clear_queue()

			self.anim_player.animation_set_next(
				atk_data.animation_name,
				self.movelist.get_from_ref_name(atk_data.recovery_ref).animation_name
			)

	self.anim_player.play(atk_data.animation_name)

# sets player stance -- extend if character has extra stances
# func set_stance_state() -> void:
# 	match self.anim_player.current_animation:
# 		"dash_f_BAKED":
# 			self.stance = STANCE.F_DASH
# 		"dash_b_BAKED":
# 			self.stance = STANCE.B_DASH
# 		"idle_crouching_BAKED", "walk_fc_BAKED":
# 			self.stance = STANCE.CROUCHING
# 		"step_l_BAKED", "step_r_BAKED":
# 			self.stance = STANCE.SIDESTEP
# 		"walk_r_BAKED", "walk_l_BAKED":
# 			self.stance = STANCE.SIDEWALK
# 		"run_f_BAKED":
# 			self.stance = STANCE.RUN
# 		"idle_standing_BAKED":
# 			self.stance = STANCE.STANDING

func get_move_from_input() -> FighterAnimationData:
	var inputs: Array = self.input_interpreter.read_input(10)

	return self.movelist.get_from_input(inputs, self.states, self.screen_position)

# region old
# func check_animation_from_input() -> String:
# 	var current_anim: String = self.anim_player.current_animation

# 	var inputs: Array = self.input_interpreter.read_input(3)

# 	var return_val: String = "idle_standing"

# 	# check if an attack button was pressed here, different procedure is needed
# 	if self.button_state != BUTTON_STATE.NONE:
# 		return_val = self.initiate_attack_anim(current_anim)
# 		if return_val != "EMPTY":
# 			return  return_val + "_BAKED" if !return_val.ends_with("_BAKED") else return_val

# 	var back_input: Callable = func() -> String:
# 		if current_anim == "dash_b":
# 			return current_anim
# 		return "walk_b"

# 	var forward_input: Callable = func() -> String:
# 		if current_anim == "dash_f":
# 			return current_anim
# 		return "walk_f"

# 	match self.di_state:
# 		DI_STATE.NEUTRAL:   
# 			if inputs.size() > 1:
# 				# handle sidestep to DOWN dir
# 				if (inputs[0].frame_start - SyncManager.current_tick) < 5 && \
# 					inputs[1].di == DI_STATE.DOWN && \
# 					(inputs[1].frame_start - inputs[0].frame_start) <= 8:
# 					if self.screen_position == "LEFT":
# 						return_val = "step_r"
# 					else:
# 						return_val = "step_l"

# 				# handle sidestep to UP dir
# 				elif (inputs[0].frame_start - SyncManager.current_tick) < 5 && \
# 					inputs[1].di == DI_STATE.UP && \
# 					(inputs[1].frame_start - inputs[0].frame_start) <= 8:
# 					if self.screen_position == "LEFT":
# 						return_val = "step_l"
# 					else:
# 						return_val = "step_r"
						
# 			if return_val == "idle_standing":
# 				if current_anim.contains("dash") || \
# 					current_anim.contains("run") || \
# 					current_anim.contains("step"):
# 					return_val = current_anim
# 				# else:
# 				# 	return_val = "idle_standing"
		
# 		DI_STATE.FORWARD:
# 			if current_anim == "dash_f_BAKED" && inputs.size() >= 3:
# 				if (inputs[0].frame_start - SyncManager.current_tick) < 2 && \
# 					inputs[1].di == DI_STATE.NEUTRAL && \
# 					(inputs[1].frame_start - inputs[0].frame_start) <= 13:
# 					return_val = "run_f"
# 				else:
# 					return_val = current_anim
# 			elif self.stance != STANCE.F_DASH && self.stance != STANCE.RUN && inputs.size() >= 3:
# 				if (inputs[0].frame_start - SyncManager.current_tick) < 2 && \
# 					inputs[1].di == DI_STATE.NEUTRAL && \
# 					(inputs[1].frame_start - inputs[0].frame_start) <= 8 && \
# 					inputs[2].di == DI_STATE.FORWARD:
# 						return_val = "dash_f"
# 				else:
# 					return_val = "walk_f"
# 			else: # running state
# 				return_val = current_anim
		
# 		DI_STATE.BACK:
# 			if current_anim == "dash_b_BAKED":
# 				return_val = current_anim
# 			elif self.stance != STANCE.B_DASH && inputs.size() >= 3:
# 				if (inputs[0].frame_start - SyncManager.current_tick) < 2 && \
# 					inputs[1].di == DI_STATE.NEUTRAL && \
# 					(inputs[1].frame_start - inputs[0].frame_start) <= 8 && \
# 					inputs[2].di == DI_STATE.BACK:
# 						return_val = "dash_b"
# 				else:
# 					return_val = "walk_b"

# 		DI_STATE.UP:
# 			if current_anim.contains("step") || \
# 				current_anim.contains("walk"):
# 				if self.screen_position == "LEFT" && \
# 					(current_anim == "walk_l_BAKED" || \
# 					current_anim == "step_l_BAKED"):
# 					return_val = "walk_l"
# 				elif self.screen_position == "RIGHT" && \
# 					(current_anim == "walk_r_BAKED" || \
# 					current_anim == "step_r_BAKED"):
# 					return_val = "walk_r"
# 				else:
# 					return_val = "idle_standing"
# 			else:
# 				return_val = "idle_standing"
			
# 		DI_STATE.UP_BACK:
# 			return_val = back_input.call()

# 		DI_STATE.UP_FORWARD:
# 			return_val = forward_input.call()

# 		DI_STATE.DOWN:
# 			if current_anim.contains("step") || \
# 				current_anim.contains("walk"):
# 				if self.screen_position == "LEFT" && \
# 					(current_anim == "walk_r_BAKED" || \
# 					current_anim == "step_r_BAKED"):
# 					return_val = "walk_r"
# 				elif self.screen_position == "RIGHT" && \
# 					(current_anim == "walk_l_BAKED" || \
# 					current_anim == "step_l_BAKED"):
# 					return_val = "walk_l"
# 				else:
# 					return_val = "idle_crouching"
# 			else:
# 				return_val = "idle_crouching"

# 		DI_STATE.DOWN_BACK:
# 			return_val = "idle_crouching"

# 		DI_STATE.DOWN_FORWARD:
# 			return_val = "walk_fc"

# 	self.current_anim_id = ""
# 	return return_val + "_BAKED" if !return_val.ends_with("_BAKED") else return_val
# endregion

# func initiate_attack_anim(_current_anim: String) -> String:
# 	var atk: String = self.movelist.get_from_input(self.di_state, self.button_state, self.states)
# 	if atk != "EMPTY":
# 		self.current_anim_id = atk
# 		return self.movelist.get_from_id(atk).animation_name
# 	return _current_anim

func process_root_motion(delta: int) -> void:

	var curr_rotation: Quaternion = self.collision_body.global_transform.basis.get_rotation_quaternion()

	self.collision_body.velocity = FixedVector3.mul(FixedVector3.div(
		FixedVector3.from_vec3(
			curr_rotation * self.anim_player.get_root_motion_position()
	), delta), 98304)

	collide_and_slide(delta)

	self.collision_body.global_transform.basis.orthonormalized()

func collide_and_slide(delta: int) -> void:

	var new_position: FixedVector3 = self.collision_body.fixed_position

	new_position.x += FixedInt.mul(self.collision_body.velocity.x, delta)
	new_position.y += FixedInt.mul(self.collision_body.velocity.y, delta)
	new_position.z += FixedInt.mul(self.collision_body.velocity.z, delta)

	var oppo_collision_body : FEFighterCollisionBody = get_tree().get_nodes_in_group(
		"Player2MainCollisionBody" if self.player == 0 \
		else "Player1MainCollisionBody"
	)[0] # this group should never be empty, and should only have 1 member

	var overlap: Variant = self.collision_body.fixed_is_overlapping_with(oppo_collision_body)

	if overlap is int:
		var change: FixedVector3 = FixedVector3.mul(
			self.collision_body.fixed_position.direction_to(oppo_collision_body.fixed_position),
			FixedInt.div(overlap, FixedInt.FIXED_TWO)
		)

		new_position.x -= change.x
		# new_position.y -= change.y
		new_position.z -= change.z

	# TODO: Collision with walls

	self.collision_body.fixed_position = new_position

	self.collision_body.fixed_look_at(oppo_collision_body.fixed_position)
	
	self.position = FixedVector3.to_vec3( \
		FixedVector3.sub(self.collision_body.fixed_position, \
			FixedVector3.from_vec3(self.collision_body_offset) \
	))

	self.rotation = FixedVector3.to_vec3(self.collision_body.fixed_rotation)
