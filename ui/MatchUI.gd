extends Control
class_name MatchUI

@onready var player_1 : Fighter = %Stage.char_container.get_node("Character")
@onready var player_2 : Fighter = %Stage.char_container.get_node("Character2")
@onready var left_side = %Left
@onready var right_side = %Right

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	display_input_history(self.player_1.input_interpreter.input_history, self.player_1.screen_position)
	display_input_history(self.player_2.input_interpreter.input_history, self.player_2.screen_position)

	# %Stage.get_parent().size = Vector2(1920, 1080)

func display_input_history(data: Array, side: String):
	var box

	if side == "LEFT":
		box = self.left_side.get_node("VBox").get_children()
	else:
		box = self.right_side.get_node("VBox").get_children()

	

	for i in  box.size():
		if i >= data.size():
			break
		
		box[i].input_val = data[(data.size()-1) - i]
