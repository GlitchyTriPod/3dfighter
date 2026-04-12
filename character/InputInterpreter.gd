extends RefCounted
class_name InputInterpreter

var input_history : Array = []

func read_input(history : int= 0) -> Array: # <- fix this to evaluate if input frame_start matches or exceeds current_tick???
	if history == 0:
		return [self.input_history.back()] # temp
	var inputs: Array = []
	for i: int in range(clamp(self.input_history.size() - history, 0, 100), self.input_history.size()):
		inputs.push_front(self.input_history[i])
	return inputs

func interpret_input(input: Dictionary, screen_position: String) -> void:
	
	var di: String = ""
	var button: String = ""

	# check directional input
	if input.has("input_directional"):
		if input["input_directional"].y == -1:
			di += "D"
		elif input["input_directional"].y == 1:
			di += "U"

		if input["input_directional"].x == 1:
			if screen_position == "LEFT":
				di += "B"
			else:
				di += "F"
		elif input["input_directional"].x == -1:
			if screen_position == "LEFT":
				di += "F"
			else:
				di += "B"

	if di == "":
		di += "N"

	# check button inputs
	if input.has("input_button"):
		if input["input_button"].has("p"):
			button += "P"
		if input["input_button"].has("k"):
			button += "K"
		if input["input_button"].has("a"):
			button += "A"
	
	if button == "":
		button += "N"

	# TODO: turn this into a bit mask
	var ret_di: int
	match di:
		"N":
			ret_di = Fighter.DI_STATE.NEUTRAL
		"U":
			ret_di = Fighter.DI_STATE.UP
		"UF":
			ret_di = Fighter.DI_STATE.UP_FORWARD
		"F":
			ret_di = Fighter.DI_STATE.FORWARD
		"DF":
			ret_di = Fighter.DI_STATE.DOWN_FORWARD
		"D":
			ret_di = Fighter.DI_STATE.DOWN
		"DB":
			ret_di = Fighter.DI_STATE.DOWN_BACK
		"B":
			ret_di = Fighter.DI_STATE.BACK
		"UB":
			ret_di = Fighter.DI_STATE.UP_BACK

	# TODO: turn this into a bit mask
	var ret_button: int
	match button:
		"N":			
			ret_button = Fighter.BUTTON_STATE.NONE
		"P":
			ret_button = Fighter.BUTTON_STATE.P
		"K":
			ret_button = Fighter.BUTTON_STATE.K
		"A":
			ret_button = Fighter.BUTTON_STATE.A
		"PK":
			ret_button = Fighter.BUTTON_STATE.PK
		"PA":
			ret_button = Fighter.BUTTON_STATE.PA
		"KA":
			ret_button = Fighter.BUTTON_STATE.KA
		"PKA":
			ret_button = Fighter.BUTTON_STATE.PKA

	var current_input : Dictionary = {
			"di": ret_di,
			"button": ret_button, 
			"frame_start": SyncManager.current_tick,
			"screen_pos": screen_position
		}

	var last_input: Variant = self.input_history.back()
	if last_input == null:
		self.input_history.append(current_input)
		return

	if current_input["frame_start"] <= last_input["frame_start"]:
		# self.input_history[self.input_history.size() - 1] = current_input
		return
	
	if current_input["di"] != last_input["di"] || current_input["button"] != last_input["button"]:

		# add input to history
		self.input_history.append(current_input)

	# trim array if necessary
	if self.input_history.size() > 20:
		self.input_history.pop_front()
