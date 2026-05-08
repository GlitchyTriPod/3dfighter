@tool
extends Node3D
class_name Fighter

@export var fighter_name: String = "DUMMY"

@export_enum("1", "2") var player: int = 0

var stun_reason: Dictionary = {
	"stun_name": "", # not really sure what im using this for rn im sure its important
	"stun_hit": -1, # used to prevent hit registering multiple times on consecutive frames
	"stun_id": "", # holds the id of the stun animation to be played
	"stun_pushback": 0 # holds the pushback force of the incoming attack
}

var states: Array[String] = []

@export var movelist: FighterMovelist

@export var animation_velocity_data: FighterResource
@export var animation_hurtbox_data: FighterResource

@export var animation_library: AnimationLibrary

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
			.get_char_position(self.player)

@onready var collision_body: FEFighterCollisionBody = %CollisionBody

var input_interpreter: InputInterpreter = InputInterpreter.new()

@onready var anim_player: NetworkAnimationPlayer = %NetworkAnimationPlayer

var current_anim_id: String = "0" # Movelist item, NOT animation name
var anim_fallback_id: String = "0"
			
var collision_body_offset: Vector3

var misc_hitbox_pool: Array[FECollisionData] = []
var misc_hurtbox_pool: Array[FECollisionData] = []

### use for debugging only ###
var _debug_hitbox_pool: Array
var _debug_hurtbox_pool: Array
##############################

var is_focused: bool = false

var is_online: bool = false

@export_storage var _velocity_bake_mode: bool = false
@export_storage var _hurtbox_bake_mode: bool = false

signal record_velocity_data(velocity: FixedVector3, animation_name: String, frame: int)
signal record_hurtbox_data(hurtboxes: Array, animation_name: String, frame: int)

### LIFE CYCLE ###
func _init() -> void:
	if OS.has_feature("show_hitboxes"):
		self._debug_hitbox_pool = []
		self._debug_hurtbox_pool = []

		# self.misc_hurtbox_pool.append(FECollisionData.new())

	# if OS.has_feature("show_hitboxes"):
		for i: int in range(0, 29, 1):
			var hurtbox: FECollisionShape = FECollisionShape.new()
			hurtbox.enabled = false
			self._debug_hurtbox_pool.append(hurtbox)

	# if OS.has_feature("show_hitboxes"):
		for i: int in range(0, 4, 1):
			var hitbox: FECollisionShape = FECollisionShape.new()
			hitbox.enabled = false
			hitbox.is_hitbox = true
			self._debug_hitbox_pool.append(hitbox)


func _ready() -> void:
	if !Engine.is_editor_hint():
	# 	self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	# else:
		%AddonSpheres.queue_free()

		for nde: Node in get_tree().get_nodes_in_group("SkeletonHurtbox"):
			nde.queue_free()

		if OS.has_feature("show_hitboxes"):
			for nde: FECollisionShape in self._debug_hitbox_pool:
				nde.shape_owner = self.get_path()
				%MiscHitboxPool.add_child(nde)
			
			for nde: FECollisionShape in self._debug_hurtbox_pool:
				nde.shape_owner = self.get_path()
				%MiscHurtboxPool.add_child(nde)

		self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		self.anim_player.playback_default_blend_time = 0.1
		self.collision_body_offset = self.collision_body.position
		self.collision_body.top_level = true

		get_window().focus_entered.connect(self._on_window_focus_entered)
		get_window().focus_exited.connect(self._on_window_focus_exited)

func _process(_delta: float) -> void:
	%AnimationNameLabel.text = self.anim_player.current_animation

	if Engine.is_editor_hint():
		if self.anim_player.current_animation.is_empty():
			return

		if self._velocity_bake_mode:
			var vel: FixedVector3 = self.process_root_motion(FixedInt.FromFloat(1.0 / 60))
			self.record_velocity_data.emit(
				vel, 
				str(self.anim_player.current_animation), 
				roundi(self.anim_player.current_animation_position * 60)
			)
		
		if self._hurtbox_bake_mode:
			self.record_hurtbox_data.emit(
				get_tree().get_nodes_in_group("SkeletonHurtbox").duplicate(true),
				str(self.anim_player.current_animation),
				roundi(self.anim_player.current_animation_position * 60)
			)

		if self._velocity_bake_mode || self._hurtbox_bake_mode:
			self.anim_player.advance(1.0 / 60)

### METHODS ###

func reset_stun_reason() -> void:
	self.stun_reason = {
		"stun_name": "",
		"stun_hit": -1,
		"stun_id": "",
		"stun_pushback": 0
	}

# checks the current animation id, sets player state based on currently playing animation
func process_animation_data() -> void:
	var atk: FighterAnimationData = self.movelist.get_from_id(self.current_anim_id)

	# check if Fighter has transitioned to fallback animation
	if atk.animation_name != self.anim_player.current_animation:
		self.current_anim_id = self.anim_fallback_id
		atk = self.movelist.get_from_id(current_anim_id)

	# if the fighter has no currently playing animation, play the intended anim
	if self.anim_player.current_animation.is_empty():
		self.anim_player.play(atk.animation_name)
		self.anim_player.seek(0, true)

	self.states = self.states.filter(
		func(state: String) -> bool:
			return state.ends_with("_calc")
	)

	# set states
	var current_frame: int = floori(self.anim_player.current_animation_position * 60)
	for state: Variant in atk.player_states:
		var state_data: Variant = atk.player_states[state]
		if current_frame >= state_data.start && \
			current_frame < state_data.end:
			if self.states.has(state):
				continue
			self.states.append(state)
	
# checks current animation for hitboxes & places them into the scene if necessary
func process_animation_hitboxes() -> void:
	if OS.has_feature("show_hitboxes"):
		for i: FECollisionShape in self._debug_hitbox_pool + self._debug_hurtbox_pool:
			i.enabled = false

	var atk: FighterAnimationData = self.movelist.get_from_id(self.current_anim_id)

	#find hitboxes
	var current_frame: int = floori(self.anim_player.current_animation_position * 60)
	var hitbox_data: Array = []
	var hurtbox_data: Array = []
	# var index: int
	if atk.hitbox_data.has("shapes"):
		for h_b: Dictionary in atk.hitbox_data["shapes"]:
			if current_frame < h_b.frame_range.start || current_frame >= h_b.frame_range.end:
				continue
			if !h_b.has("is_hitbox"):
				h_b["is_hitbox"] = true
			# h_b["is_hitbox"] = true
			hitbox_data.append(h_b)

	if atk.hurtbox_data.has("shapes"):
		for h_b: Dictionary in atk.hurtbox_data["shapes"]:
			if current_frame < h_b.frame_range.start || current_frame >= h_b.frame_range.end:
				continue
			
			if !h_b.has("is_hitbox"):
				h_b["is_hitbox"] = false
			# h_b["is_hitbox"] = false
			hurtbox_data.append(h_b)
	
	hurtbox_data.append_array(self.get_animation_hurtboxes())

	self.misc_hurtbox_pool = FECollisionData.create_from_arr(hurtbox_data)
	self.misc_hitbox_pool = FECollisionData.create_from_arr(hitbox_data)

	### Debug only ###
	if OS.has_feature("show_hitboxes"):
		for shape: FECollisionData in self.misc_hitbox_pool + self.misc_hurtbox_pool:
			var h_b: FECollisionShape
			if shape.is_hitbox:
				h_b = self.get_debug_unused_hitbox()
			else:
				h_b = self.get_debug_unused_hurtbox()
			h_b.copy_collision_data(shape)

	# #################

func get_animation_hurtboxes() -> Array:
	var boxes: Array = self.animation_hurtbox_data.dict.get(
		self.anim_player.current_animation
	).get(
		str(floori(self.anim_player.current_animation_position * 60))
	)
	return boxes

# checks if current fighter is intersecting with an enemy hitbox & returns true if intersection was found
func process_hitbox_intersection() -> bool:
	var enemy_hitboxes: Array = self.message_bus.get_oppo_hitboxes(self)
	var enemy_position: FixedVector3 = self.message_bus.get_oppo_fixed_position(self)
	var enemy_rotation: FixedVector3 = self.message_bus.get_oppo_fixed_rotation(self)

	for hitbox: FECollisionData in enemy_hitboxes:
		if !hitbox.enabled || \
			((hitbox.hitbox_attack_index == self.stun_reason.stun_hit && \
			self.stun_reason.stun_hit != -1 && \
			hitbox.hitbox_attack_name == self.stun_reason.stun_name)): 
			continue
		
		# Check for early break conditions here (high atk vs. crouching opp., etc.)
		match hitbox.attack_height:
			FECollisionData.ATTACK_HEIGHT.HIGH:
				if self.states.has("crouching") || self.states.has("evade_high"):
					continue
			FECollisionData.ATTACK_HEIGHT.LOW, \
			FECollisionData.ATTACK_HEIGHT.LOW_SPECIAL:
				if self.states.has("evade_low"):
					continue

		if hitbox.final_position == null:
			hitbox.final_position = FixedVector3.Add(
				hitbox.fixed_position.Rotated(
					enemy_rotation.y
				),
				FixedVector3.NewFromInt(
					enemy_position.x,
					0,
					enemy_position.z
				)
			)

		for hurtbox: FECollisionData in self.misc_hurtbox_pool:
			if !hurtbox.enabled:
				continue

			if hurtbox.final_position == null:
				hurtbox.final_position = FixedVector3.Add(
					hurtbox.fixed_position.Rotated(
						self.collision_body.fixed_rotation.y
					),
					FixedVector3.NewFromInt(
						self.collision_body.fixed_position.x,
						0,
						self.collision_body.fixed_position.z
					)
				)
			
			if hurtbox.fixed_is_overlapping_with(hitbox) > 0:
				# incoming hit detected!
				var blocked: bool = false
				if (self.states.has("guard_high") || self.states.has("neutral_guard_high")) && \
					(hitbox.attack_height == FECollisionData.ATTACK_HEIGHT.HIGH || \
					hitbox.attack_height ==  FECollisionData.ATTACK_HEIGHT.MEDIUM || \
					hitbox.attack_height ==  FECollisionData.ATTACK_HEIGHT.MEDIUM_SPECIAL || \
					hitbox.attack_height ==  FECollisionData.ATTACK_HEIGHT.LOW_SPECIAL):
					blocked = true
				if (self.states.has("guard_low") || self.states.has("neutral_guard_low")) && \
					(hitbox.attack_height == FECollisionData.ATTACK_HEIGHT.LOW || \
					hitbox.attack_height ==  FECollisionData.ATTACK_HEIGHT.MEDIUM_SPECIAL || \
					hitbox.attack_height ==  FECollisionData.ATTACK_HEIGHT.LOW_SPECIAL):
					blocked = true

				self.process_hit(
					hitbox.hitbox_attack_index, 
					hitbox.hitbox_attack_name, 
					self.message_bus.get_oppo_current_animation_id(self),
					blocked
				)
				return blocked
	return false

func process_hit(attack_index: int, animation_name: String, animation_id: String, blocked: bool = false) -> void:
	var enemy_anim_data: FighterAnimationData = self.message_bus.get_oppo_current_animation_data(self, animation_id)

	var stun_move: String

	if blocked:
		stun_move = self.movelist.get_default_anim_id_from_name(enemy_anim_data.block_animation)
	else:
		if self.states.has("counterable"):
			stun_move = self.movelist.get_default_anim_id_from_name(enemy_anim_data.counter_animation)
		else:
			stun_move = self.movelist.get_default_anim_id_from_name(enemy_anim_data.hit_animation)

	self.stun_reason.stun_hit = attack_index
	self.stun_reason.stun_name = animation_name
	self.stun_reason.stun_id = stun_move
	self.stun_reason.stun_pushback = enemy_anim_data.pushback_force

# processes movement for player
func process_movement(delta: int, attack_blocked: bool = false) -> void: # could use some optimizing
	# if attack has been blocked, check if current attack has unique on-block animation, then override.
	if attack_blocked:
		var anim_data: FighterAnimationData = self.movelist.get_from_id(self.current_anim_id)
		if anim_data.has_block_recovery:
			self.stun_reason.stun_id = self.movelist.get_default_anim_id_from_name(anim_data.recovery_block)

	# check if fighter needs to be placed in a stun animation
	if self.stun_reason.stun_id != "":
		var move: FighterAnimationData = self.movelist.get_from_id(self.stun_reason.stun_id)
		self.set_animation_order(move)
		self.process_root_motion(delta, self.stun_reason.stun_pushback)
		self.reset_stun_reason()
		return

	# if player is not actionable they cannot cancel current animation; keep playing
	if !self.states.has("actionable") || self.states.has("hit_stun") || self.states.has("block_stun"):
		var move: FighterAnimationData = self.movelist.get_from_id(self.current_anim_id)
		if move.animation_name != self.anim_player.current_animation:
			self.set_animation_order(self.movelist.get_from_ref_name(move.recovery_ref))

		self.process_root_motion(delta)

		return

	var inp: Array[Dictionary] = self.input_interpreter.read_input()
	if inp.size() == 0 || inp[0] == null:
		return

	# determine animation to play
	var next_move: FighterAnimationData = self.get_move_from_input()

	if next_move != null && \
		next_move.animation_name != self.anim_player.current_animation && \
		!self.is_current_input_ignored(inp):
		self.set_animation_order(next_move)

	self.process_root_motion(delta)

func set_animation_order(atk_data: FighterAnimationData) -> void:
	if !atk_data.recovery_ref.is_empty():
			self.anim_player.clear_queue()

			var recovery_move: FighterAnimationData = self.movelist.get_from_ref_name(atk_data.recovery_ref)

			self.anim_player.animation_set_next(
				atk_data.animation_name,
				recovery_move.animation_name
			)

			self.anim_fallback_id = self.movelist.get_move_id(recovery_move)

	self.current_anim_id = self.movelist.get_move_id(atk_data)
	self.anim_player.play(atk_data.animation_name)
	self.anim_player.seek(0)
	
func is_current_input_ignored(current_input: Array[Dictionary]) -> bool:
	if current_input[0].button != 0:
		return false

	match current_input[0].di:
		DI_STATE.NEUTRAL:
			if self.states.has("recovery_ignore_input_NEUTRAL"):
				return true
		DI_STATE.UP:
			if self.states.has("recovery_ignore_input_UP"):
				return true
		DI_STATE.UP_FORWARD:
			if self.states.has("recovery_ignore_input_UP_FORWARD"):
				return true
		DI_STATE.FORWARD:
			if self.states.has("recovery_ignore_input_FORWARD"):
				return true
		DI_STATE.DOWN_FORWARD:
			if self.states.has("recovery_ignore_input_DOWN_FORWARD"):
				return true
		DI_STATE.DOWN:
			if self.states.has("recovery_ignore_input_DOWN"):
				return true
		DI_STATE.DOWN_BACK:
			if self.states.has("recovery_ignore_input_DOWN_BACK"):
				return true
		DI_STATE.BACK:
			if self.states.has("recovery_ignore_input_BACK"):
				return true
		DI_STATE.UP_BACK:
			if self.states.has("recovery_ignore_input_UP_BACK"):
				return true
				
	return false

func get_move_from_input() -> FighterAnimationData:
	var inputs: Array[Dictionary] = self.input_interpreter.read_input(10)

	return self.movelist.get_from_input(inputs, self.states, self.screen_position)

func process_root_motion(delta: int, pushback_force: int = -1) -> Variant:

	#### for use INSIDE editor only ####
	if Engine.is_editor_hint():
		var frame_velocity: FixedVector3 = \
			FixedVector3.FromVec3(self.anim_player.get_root_motion_position())
		return frame_velocity
	#####################################

	var curr_rotation: FixedVector3 = self.collision_body.fixed_rotation
	var vel: FixedVector3 = FixedVector3.NewFromFixedVec3(self.get_root_motion())

	# vel.z -= self.collision_body.pushback_force

	# velocity rotation (to match currently facing direction)
	var vel_rot: FixedVector3 = vel.Rotated(
		curr_rotation.y
	)

	# add pushback velocity to vel_rot
	if pushback_force != -1 && self.collision_body.pushback_force == 0:
		self.collision_body.pushback_force = pushback_force

	self.collision_body.pushback_force = CollisionMath.CalculatePushback(
		self.collision_body.pushback_force, self.anim_player.current_animation_position
	)
	
	vel_rot = FixedVector3.Add( 
		vel_rot,
		FixedVector3.NewFromInt(0, 0, self.collision_body.pushback_force).Rotated(
			self.message_bus.get_oppo_fixed_rotation(self).y
		)
	)

	self.collision_body.velocity = FixedVector3.Mul(
		FixedVector3.Div(
			vel_rot,
			delta
		),
		FixedIntGDConstant.FIXED_ONE
	)

	collide_and_slide(delta)

	return

func get_root_motion() -> FixedVector3:
	var vel: FixedVector3 = self.animation_velocity_data.dict.get(
		self.anim_player.current_animation
	).get(
		str(floori(self.anim_player.current_animation_position * 60))
	)

	return vel

func collide_and_slide(delta: int) -> void:

	var new_position: FixedVector3 = self.collision_body.fixed_position

	new_position = FixedVector3.Add(new_position, FixedVector3.Mul(self.collision_body.velocity, delta))

	######### used OUTSIDE editor only #########
	if !Engine.is_editor_hint():

		var oppo_collision_body: FEFighterCollisionBody = self.message_bus.get_oppo_collision_body(self)

		var overlap: int = self.collision_body.fixed_is_overlapping_with(oppo_collision_body)

		if overlap > 0:
			var change: FixedVector3 = FixedVector3.Mul(
				self.collision_body.fixed_position.DirectionTo(oppo_collision_body.fixed_position),
				FixedInt.Div(abs(overlap), FixedIntGDConstant.FIXED_TWO)
			)

			new_position.x -= change.x
			# new_position.y -= change.y 
			new_position.z -= change.z

		# TODO: Collision with walls

		self.collision_body.fixed_position = new_position

		if self.is_tracking_opponent():
			self.collision_body.fixed_look_at(
				oppo_collision_body.fixed_position,
				FixedVector3.NewFromInt(0, FixedIntGDConstant.FIXED_ONE, 0))
	############################################

	self.position = self.collision_body.global_position - self.collision_body_offset
	self.rotation = self.collision_body.global_rotation

func is_tracking_opponent() -> bool:
	var oppo_states: PackedStringArray = self.message_bus.get_oppo_states(self)
	if self.states.has("track_opp") || \
		(self.states.has("track_right") && oppo_states.has("left_movement")) || \
		(self.states.has("track_left") && oppo_states.has("right_movement")):
		return true
	return false

func get_debug_unused_hitbox() -> Variant:
	for i: FECollisionShape in self._debug_hitbox_pool:
		if !i.enabled:
			return i
	var new: FECollisionShape = FECollisionShape.new()
	new.is_hitbox = true
	self._debug_hitbox_pool.append(new)
	%MiscHitboxPool.add_child(new)
	return new

func get_debug_unused_hurtbox() -> Variant:
	for i: FECollisionShape in self._debug_hurtbox_pool:
		if !i.enabled:
			return i
	var new: FECollisionShape = FECollisionShape.new()
	self._debug_hurtbox_pool.append(new)
	%MiscHurtboxPool.add_child(new)
	return new

### LISTENERS ###

func _on_window_focus_entered() -> void:
	self.is_focused = true

func _on_window_focus_exited() -> void:
	self.is_focused = false

func _network_preprocess(input: Dictionary) -> void:
	self.input_interpreter.interpret_input(input, self.screen_position)

func _network_postprocess(_input: Dictionary) -> void:
	FECollisionData.pool_return_arr(self.misc_hitbox_pool)
	FECollisionData.pool_return_arr(self.misc_hurtbox_pool)
	self.misc_hitbox_pool.clear()
	self.misc_hurtbox_pool.clear()

func _get_local_input() -> Dictionary:
	var player_input: Dictionary = {}

	if !self.is_focused:
		
		return player_input

	var dir: Vector2i = Vector2i(
		int(Input.is_action_pressed("INPUT_LEFT_P" + str(1 if self.is_online else (self.player + 1)))) - \
		int(Input.is_action_pressed("INPUT_RIGHT_P" + str(1 if self.is_online else (self.player + 1)))),
		int(Input.is_action_pressed("INPUT_UP_P" + str(1 if self.is_online else (self.player + 1)))) - \
		int(Input.is_action_pressed("INPUT_DOWN_P" + str(1 if self.is_online else (self.player + 1))))
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
		"current_anim_id": self.current_anim_id,
		"anim_fallback_id": self.anim_fallback_id
	}

func _load_state(state: Dictionary) -> void:
	self.input_interpreter.input_history = state.input_history.duplicate()
	self.current_anim_id = state.current_anim_id
	self.anim_fallback_id = state.anim_fallback_id
