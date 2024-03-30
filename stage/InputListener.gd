extends Node

@onready var player_1: Fighter = get_node("../Chars").get_child(0)
@onready var player_2: Fighter = get_node("../Chars").get_child(1)

# Called when the node enters the scene tree for the first time.
# func _ready():
# 	pass # Replace with function body.


# # Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var p1_input : Array[String] = []
	var p2_input : Array[String] = []

	if Input.is_action_pressed("INPUT_UP_P1"):
		p1_input.append("up")
	if Input.is_action_pressed("INPUT_DOWN_P1"):
		p1_input.append("down")
	if Input.is_action_pressed("INPUT_LEFT_P1"):
		p1_input.append("left")
	if Input.is_action_pressed("INPUT_RIGHT_P1"):
		p1_input.append("right")
	if Input.is_action_pressed("INPUT_PUNCH_P1"):
		p1_input.append("p")
	if Input.is_action_pressed("INPUT_KICK_P1"):
		p1_input.append("k")
	if Input.is_action_pressed("INPUT_ABILITY_P1"):
		p1_input.append("a")

	if Input.is_action_pressed("INPUT_UP_P2"):
		p2_input.append("up")
	if Input.is_action_pressed("INPUT_DOWN_P2"):
		p2_input.append("down")
	if Input.is_action_pressed("INPUT_LEFT_P2"):
		p2_input.append("left")
	if Input.is_action_pressed("INPUT_RIGHT_P2"):
		p2_input.append("right")
	if Input.is_action_pressed("INPUT_PUNCH_P2"):
		p2_input.append("p")
	if Input.is_action_pressed("INPUT_KICK_P2"):
		p2_input.append("k")
	if Input.is_action_pressed("INPUT_ABILITY_P2"):
		p2_input.append("a")
	
	self.player_1.input(p1_input)
	self.player_2.input(p2_input)

