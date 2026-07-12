extends Control
class_name MatchUI

@onready var player_1 : Fighter = %Stage.char_container.get_child(0)
@onready var player_2 : Fighter = %Stage.char_container.get_child(1)
@onready var left_side: VBoxContainer = %Left
@onready var right_side: VBoxContainer = %Right

var p1_def_side : int = 0
var p2_def_side : int = 1

func _ready() -> void:
	if %Stage/GameCamera.default_pos == 1:
		self.p1_def_side = 1
		self.p2_def_side = 0
	
	self.player_2.update_combo_counter.connect(_update_combo_counter)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	display_input_history(self.player_1.input_interpreter.input_history, 0)
	display_input_history(self.player_2.input_interpreter.input_history, 1)

func display_input_history(data: Array, player: int) -> void:
	var box: Array[Node]

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

	for i: int in box.size():
		if i >= data.size():
			break
		
		box[i].input_val = data[(data.size()-1) - i]


################################################

func _update_combo_counter(count: int) -> void:
	if count <= 1:
		return
		
	%ComboCounter.text = "%d Hits!" % count
	%ComboCounter.visible = true

	%Timer.start(2.5)

func _on_timer_timeout() -> void:
	%ComboCounter.visible = false
