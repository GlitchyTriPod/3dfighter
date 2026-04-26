@tool
extends Node3D
class_name Fighter

@export var fighter_name: String = "DUMMY"

# @expor 
@export_enum("1", "2") var player: int = 0

var stun_reason: Dictionary = {
	"stun_name": "", # not really sure what im using this for rn im sure its important
	"stun_hit": -1, # used to prevent hit registering multiple times on consecutive frames
	"stun_id": "" # holds the id of the stun animation to be played
}

# vvv TODO: change this to PackedStringArray
var states: PackedStringArray = []

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
			.get_char_position( \
				FixedVector3.to_vec3(self.collision_body.fixed_position)
			)

@onready var collision_body: FEFighterCollisionBody = %CollisionBody

var input_interpreter: InputInterpreter = InputInterpreter.new()

@onready var anim_player: NetworkAnimationPlayer = %NetworkAnimationPlayer

var current_anim_id: String = "0" # Movelist item, NOT animation name
var anim_fallback_id: String = "0"
			
var collision_body_offset: Vector3

@onready var misc_hitbox_pool: Array = %MiscHitboxPool.get_children()
@onready var misc_hurtbox_pool: Array = %MiscHurtboxPool.get_children()

var is_focused: bool = false

var is_online: bool = false

@export var _velocity_bake_mode: bool = false
@export var _hurtbox_bake_mode: bool = false

signal record_velocity_data(velocity: FixedVector3)
signal record_hurtbox_data(hurtboxes: Array)

### LIFE CYCLE ###

func _ready() -> void:
	if Engine.is_editor_hint():
		self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	else:
		%AddonSpheres.queue_free()

		for nde: Node in get_tree().get_nodes_in_group("SkeletonHurtbox"):
			nde.queue_free()

		self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		self.anim_player.playback_default_blend_time = 0.1
		self.collision_body_offset = self.collision_body.position
		self.collision_body.top_level = true

	get_window().focus_entered.connect(self._on_window_focus_entered)
	get_window().focus_exited.connect(self._on_window_focus_exited)

func _process(_delta: float) -> void:
	%AnimationNameLabel.text = self.anim_player.current_animation

	if Engine.is_editor_hint(): 
		if self._velocity_bake_mode:
			var vel: FixedVector3 = self.process_root_motion(FixedInt.from_float(1.0 / 60))
			self.record_velocity_data.emit(vel)
		
		if self._hurtbox_bake_mode:
			self.record_hurtbox_data.emit(get_tree().get_nodes_in_group("SkeletonHurtbox"))

		if self._velocity_bake_mode || self._hurtbox_bake_mode:
			self.anim_player.advance(1.0 / 60)

### METHODS ###

func reset_stun_reason() -> void:
	self.stun_reason = {
		"stun_name": "",
		"stun_hit": -1,
		"stun_id": ""
	}

# checks the current animation id, sets player state based on currently playing animation
func process_animation_data() -> void:
	var atk: FighterAnimationData = self.movelist.get_from_id(self.current_anim_id)

	# check if Fighter has transitioned to fallback animation
	if atk.animation_name != self.anim_player.current_animation:
		self.current_anim_id = self.anim_fallback_id
		atk = self.movelist.get_from_id(current_anim_id)

	for state: String in self.states:
		if !state.ends_with("_calc"):
			self.states.erase(state)

	# set states
	var current_frame: int = floori(self.anim_player.current_animation_position * 60)
	# if self.player == 0: print(current_frame)
	for state: String in atk.player_states.keys():

		# if self.states.has(state):
		var state_data: Variant = atk.player_states.get(state)
		if current_frame >= state_data.start && \
			current_frame < state_data.end:
			if self.states.has(state):
				continue
			self.states.append(state)
	

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
	var current_frame: int = floori(self.anim_player.current_animation_position * 60)
	var hitbox_data: Array = []
	# var index: int
	if atk.hitbox_data.has("shapes"):
		for h_b: Dictionary in atk.hitbox_data["shapes"]:
			if current_frame < h_b.frame_range.start || current_frame >= h_b.frame_range.end:
				continue
			hitbox_data.append(h_b)
			# index = atk.hitbox_data["shapes"].find(h_b)
			break
	
	if hitbox_data.is_empty():
		return

	for shape: Dictionary in hitbox_data:
		var hitbox: FECollisionShape = self.get_misc_unused_hitbox() # as FECollisionShape
		if hitbox == null:
			break
		# hitbox.hitbox_attack_index = index
		hitbox.hitbox_attack_name = atk.animation_name
		hitbox.fixed_position = shape.position
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
		# print(self.stun_reason.stun_id.split("/").get(1))

		self.set_animation_order(self.movelist.get_from_id(self.stun_reason.stun_id))
		self.reset_stun_reason()
		self.process_root_motion(delta)
		return

	# if player is not actionable they cannot cancel current animation; keep playing
	if !self.states.has("actionable"):
		# if self.anim_player.is_playing():
		# 	self.anim_player.advance(SyncManager.tick_time )#float(delta / 65536.0))

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

	# assert(!(next_move.move_name == "idle" && self.anim_player.current_animation == "def_animations/def_dash_b" ))

	if next_move != null && \
		next_move.animation_name != self.anim_player.current_animation && \
		!self.is_current_input_ignored(inp):
		self.set_animation_order(next_move)

	self.process_root_motion(delta)

func set_animation_order(atk_data: FighterAnimationData) -> void:
	if !atk_data.recovery_ref.is_empty():
			self.anim_player.clear_queue()

			var recovery_move: FighterAnimationData = self.movelist.get_from_ref_name(atk_data.recovery_ref)
			# self.anim_fallback_id = self.movelist.get_move_id(recovery_move)

			self.anim_player.animation_set_next(
				atk_data.animation_name,
				recovery_move.animation_name
			)

			self.anim_fallback_id = self.movelist.get_move_id(recovery_move)

	self.current_anim_id = self.movelist.get_move_id(atk_data)
	self.anim_player.play(atk_data.animation_name)
	
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

func process_root_motion(delta: int) -> Variant:

	#### for use INSIDE editor only ####
	if Engine.is_editor_hint():
		var frame_velocity: FixedVector3 = \
			FixedVector3.from_vec3(self.anim_player.get_root_motion_position())
		return frame_velocity
	#####################################

	# velocity rotation (to match currently facing direction)

	# euler method
	var curr_rotation: FixedVector3 = self.collision_body.fixed_rotation

	var vel: FixedVector3 = self.get_root_motion() #.rotate(Vector3.UP, curr_rotation.y)
	var vel_rot: FixedVector3 = vel.rotated(FixedVector3.UP, curr_rotation.y)


	self.collision_body.velocity = FixedVector3.mul(
		FixedVector3.div(
			vel_rot, #self.get_root_motion().rotate(Vector3.UP, curr_rotation.y),
			delta
		),
		FixedInt.FIXED_ONE
	)

	collide_and_slide(delta)

	return

func get_root_motion() -> FixedVector3:
	var vel: FixedVector3 = self.animation_velocity_data.resource.get(
		self.anim_player.current_animation
	).get(
		str(floori(self.anim_player.current_animation_position * 60))
	)

	return vel

func collide_and_slide(delta: int) -> void:

	var new_position: FixedVector3 = self.collision_body.fixed_position

	new_position.x += FixedInt.mul(self.collision_body.velocity.x, delta)
	new_position.y += FixedInt.mul(self.collision_body.velocity.y, delta)
	new_position.z += FixedInt.mul(self.collision_body.velocity.z, delta)

	######### used OUTSIDE editor only #########
	if !Engine.is_editor_hint():

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

		if self.is_tracking_opponent():
			self.collision_body.fixed_look_at(oppo_collision_body.fixed_position)
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

### LISTENERS ###

func _on_window_focus_entered() -> void:
	self.is_focused = true

func _on_window_focus_exited() -> void:
	self.is_focused = false

func get_misc_unused_hitbox() -> Variant:
	for i: FECollisionShape in self.misc_hitbox_pool:
		if !i.enabled:
			return i
	return

func _network_preprocess(input: Dictionary) -> void:
	self.input_interpreter.interpret_input(input, self.screen_position)
	# emit_signal("ready_for_input_process", self)

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
