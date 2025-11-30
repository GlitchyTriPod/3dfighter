extends Node

@onready var player_1: Fighter = get_node("../Chars").get_child(0)
@onready var player_2: Fighter = get_node("../Chars").get_child(1)

var process_ready := false

# Called when the node enters the scene tree for the first time.
func _ready():
	self.process_ready = true


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# delta will change with rollback implementation
func _process(_delta: float):

	var _delta_int = int(_delta * 65536)

	# first, poll for inputs
	var p1_input := _poll_player_input(1)
	var p2_input := _poll_player_input(2)
	
	self.player_1.input(p1_input)
	self.player_2.input(p2_input)

	if !self.process_ready: return

	# second, set animation data, detect hitbox + hurtbox collisions
	self.player_1.process_animation_data()
	self.player_2.process_animation_data()

	# self.player_1.process_hitbox_intersection()
	# self.player_2.process_hitbox_intersection()

	# last, advance player animations based on inputs & game state
	self.player_1.process_movement(_delta_int)
	self.player_2.process_movement(_delta_int)

# polls inputs from players
# TODO: Add networked inputs
func _poll_player_input(player: int = 0) -> Array[String]:
	var player_input : Array[String] = []

	if Input.is_action_pressed("INPUT_UP_P" + str(player)):
		player_input.append("up")
	if Input.is_action_pressed("INPUT_DOWN_P" + str(player)):
		player_input.append("down")
	if Input.is_action_pressed("INPUT_LEFT_P" + str(player)):
		player_input.append("left")
	if Input.is_action_pressed("INPUT_RIGHT_P" + str(player)):
		player_input.append("right")
	if Input.is_action_pressed("INPUT_PUNCH_P" + str(player)):
		player_input.append("p")
	if Input.is_action_pressed("INPUT_KICK_P" + str(player)):
		player_input.append("k")
	if Input.is_action_pressed("INPUT_ABILITY_P" + str(player)):
		player_input.append("a")

	return player_input
