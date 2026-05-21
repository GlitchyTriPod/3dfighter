extends RefCounted
class_name InputInterpreter

var input_history: Array[Dictionary] = []

enum BUTTON_FLAGS {
	P = 0x01,
	K = 0x02,
	A = 0x04
}

func read_input(history: int = 0) -> Array[Dictionary]: 
	if history == 0:
		return [self.input_history.back()] # temp
	var inputs: Array[Dictionary] = []
	for i: int in range(clamp(self.input_history.size() - history, 0, 100), self.input_history.size()):
		inputs.push_front(self.input_history[i])
	return inputs

func interpret_input(input: Dictionary, screen_position: int) -> void:
	
	# var di: String = ""
	# var button: String = ""

	# check directional input
	# if input.has(&"input_directional"):
	# 	if input["input_directional"].y == -1:
	# 		di += "D"
	# 	elif input["input_directional"].y == 1:
	# 		di += "U"

	# 	if input["input_directional"].x == 1:
	# 		if screen_position == 1:
	# 			di += "B"
	# 		else:
	# 			di += "F"
	# 	elif input["input_directional"].x == -1:
	# 		if screen_position == 1:
	# 			di += "F"
	# 		else:
	# 			di += "B"

	# if di == "":
	# 	di += "N"

	# # check button inputs
	# if input.has("input_button"):
	# 	if input["input_button"].has("p"):
	# 		button += "P"
	# 	if input["input_button"].has("k"):
	# 		button += "K"
	# 	if input["input_button"].has("a"):
	# 		button += "A"
	
	# if button == "":
	# 	button += "N"

	# TODO: turn this into a bit mask
	var ret_di: int
	match input.get(&"input_directional"):
		Vector2i.ZERO:
			ret_di = Fighter.DI_STATE.NEUTRAL
		Vector2i.UP:
			ret_di = Fighter.DI_STATE.UP
		Vector2i.DOWN:
			ret_di = Fighter.DI_STATE.DOWN
		Vector2i.LEFT:
			if screen_position == 1:
				ret_di = Fighter.DI_STATE.BACK
			else:
				ret_di = Fighter.DI_STATE.FORWARD
		Vector2i.RIGHT:
			if screen_position == 1:
				ret_di = Fighter.DI_STATE.FORWARD
			else:
				ret_di = Fighter.DI_STATE.BACK
		Vector2i.ONE:
			if screen_position == 1:
				ret_di = Fighter.DI_STATE.UP_FORWARD
			else:
				ret_di = Fighter.DI_STATE.UP_BACK
		-Vector2i.ONE:
			if screen_position == 1:
				ret_di = Fighter.DI_STATE.DOWN_BACK
			else:
				ret_di = Fighter.DI_STATE.DOWN_FORWARD
		Vector2i(1, -1):
			if screen_position == 1:
				ret_di = Fighter.DI_STATE.DOWN_FORWARD
			else:
				ret_di = Fighter.DI_STATE.DOWN_BACK
		Vector2i(-1, 1):
			if screen_position == 1:
				ret_di = Fighter.DI_STATE.UP_BACK
			else:
				ret_di = Fighter.DI_STATE.UP_FORWARD
		

	# match di:
	# 	"N":
	# 		ret_di = Fighter.DI_STATE.NEUTRAL
	# 	"U":
	# 		ret_di = Fighter.DI_STATE.UP
	# 	"UF":
	# 		ret_di = Fighter.DI_STATE.UP_FORWARD
	# 	"F":
	# 		ret_di = Fighter.DI_STATE.FORWARD
	# 	"DF":
	# 		ret_di = Fighter.DI_STATE.DOWN_FORWARD
	# 	"D":
	# 		ret_di = Fighter.DI_STATE.DOWN
	# 	"DB":
	# 		ret_di = Fighter.DI_STATE.DOWN_BACK
	# 	"B":
	# 		ret_di = Fighter.DI_STATE.BACK
	# 	"UB":
	# 		ret_di = Fighter.DI_STATE.UP_BACK

	# var ret_button: int = 0
	# if button.contains("P"):
	# 	ret_button |= BUTTON_FLAGS.P
	# if button.contains("K"):
	# 	ret_button |= BUTTON_FLAGS.K
	# if button.contains("A"):
	# 	ret_button |= BUTTON_FLAGS.A

	var current_input: Dictionary[StringName, Variant] = {
			&"di": ret_di,
			&"button": input.get(&"input_button"), 
			&"frame_start": SyncManager.current_tick,
			&"screen_pos": screen_position
		}

	var last_input: Dictionary = self.input_history.back() if !self.input_history.is_empty() else {}
	if last_input.is_empty():
		self.input_history.append(current_input)
		return

	if current_input[&"frame_start"] <= last_input[&"frame_start"]:
		return
	
	if current_input[&"di"] != last_input[&"di"] || current_input[&"button"] != last_input[&"button"]:

		# add input to history
		self.input_history.append(current_input)

	# trim array if necessary
	if self.input_history.size() > 20:
		self.input_history.pop_front()
