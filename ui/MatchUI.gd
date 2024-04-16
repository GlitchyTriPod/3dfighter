extends Control
class_name MatchUI

@onready var player_1 : Fighter = %Stage.char_container.get_node("Fighter")
@onready var player_2 : Fighter = %Stage.char_container.get_node("Fighter2")
@onready var left_side = %Left
@onready var right_side = %Right

var p1_def_side := 0
var p2_def_side := 1

func _ready():
	if %Stage/GameCamera.default_pos == 1:
		self.p1_def_side = 1
		self.p2_def_side = 0
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	display_input_history(self.player_1.input_interpreter.input_history, 0)
	display_input_history(self.player_2.input_interpreter.input_history, 1)

	# %Stage.get_parent().size = Vector2(1920, 1080)

func display_input_history(data: Array, player: int):
	var box

	if player == 0:
		if self.p1_def_side == 0:
			box = self.left_side.get_node("VBox").get_children()
		else:
			box = self.right_side.get_node("VBox").get_children()
	else:
		if self.p2_def_side == 0:
			box = self.left_side.get_node("VBox").get_children()
		else:
			box = self.right_side.get_node("VBox").get_children()

	

	for i in  box.size():
		if i >= data.size():
			break
		
		box[i].input_val = data[(data.size()-1) - i]
