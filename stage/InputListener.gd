extends Node
class_name InputListener

@onready var player_1: Fighter = get_node("../Chars").get_child(0)
@onready var player_2: Fighter = get_node("../Chars").get_child(1)

var _p1_ready : bool = false
var _p2_ready : bool = false

# @onready var timer: NetworkTimer = get_child(0)

var is_p1_local : bool = true
var is_p2_local : bool = true

# var process_ready := false

var is_online_match : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# SyncManager.connect_signal(self.player_1, "ready_for_input_process", self, "_player_ready_process")
	# SyncManager.connect_signal(self.player_2, "ready_for_input_process", self, "_player_ready_process")

	self.player_1.ready_for_input_process.connect(_player_process_ready)
	self.player_2.ready_for_input_process.connect(_player_process_ready)

# 	self.timer.timeout.connect(self._on_timer_timeout)
	# self.process_ready = true

	# # check if current match is online, set players based on connection
	# if self.is_online_match:
	# 	if !multiplayer.is_server():

# func _on_timer_timeout():
# 	self.process_ready = true
# 	self.player_1.process_inputs = true
# 	self.player_2.process_inputs = true

func _player_process_ready(player: Fighter) -> void:
	if player == self.player_1:
		self._p1_ready = true
	else:
		self._p2_ready = true

	if self._p1_ready && self._p2_ready:
		input_process()
		self._p1_ready = false
		self._p2_ready = false

# # Called every network tick. 'delta' is the elapsed time since the previous frame.
# delta will change with rollback implementation
func input_process() -> void: #_input: Dictionary): #_delta: float):

	# first, poll for inputs
	# check if player is local or networked
	# var p1_input := _poll_player_input(1)
	# var p2_input := _poll_player_input(2)
	
	# self.player_1.input(p1_input)
	# self.player_2.input(p2_input)

	# if !self.process_ready:
	# 	return

	var _delta_int: int = int(SyncManager.tick_time * 65536) #int(_delta * 65536)

	# set player states based on animation data
	self.player_1.process_animation_data()
	self.player_2.process_animation_data()

	# enable/disable hit/hurtboxes for player based on anim data
	self.player_1.process_animation_hitboxes()
	self.player_2.process_animation_hitboxes()

	# check for hit/hurtbox intersections
	self.player_1.process_hitbox_intersection()
	self.player_2.process_hitbox_intersection()

	#advance player animations based on inputs & game state
	self.player_1.process_movement(_delta_int)
	self.player_2.process_movement(_delta_int)


# func _save_state() -> Dictionary:
# 	return {
# 		"process_ready": self.process_ready
# 	}

# func _load_state(states: Dictionary):
# 	self.process_ready = states["process_ready"]

# func _get_local_input() -> Dictionary:
# 	pass


# polls inputs from players
# TODO: Add networked inputs
# func _poll_player_input(player: int = 0) -> Array[String]:
# 	var player_input : Array[String] = []

# 	if Input.is_action_pressed("INPUT_UP_P" + str(player)):
# 		player_input.append("up")
# 	if Input.is_action_pressed("INPUT_DOWN_P" + str(player)):
# 		player_input.append("down")
# 	if Input.is_action_pressed("INPUT_LEFT_P" + str(player)):
# 		player_input.append("left")
# 	if Input.is_action_pressed("INPUT_RIGHT_P" + str(player)):
# 		player_input.append("right")
# 	if Input.is_action_pressed("INPUT_PUNCH_P" + str(player)):
# 		player_input.append("p")
# 	if Input.is_action_pressed("INPUT_KICK_P" + str(player)):
# 		player_input.append("k")
# 	if Input.is_action_pressed("INPUT_ABILITY_P" + str(player)):
# 		player_input.append("a")

# 	return player_input
