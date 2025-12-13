extends RefCounted
class_name InputInterpreter

var input_history : Array = []

func read_input(history := 0) -> Array: # <- fix this to evaluate if input frame_start matches or exceeds current_tick
	if history == 0:
		return [self.input_history.back()] # temp
	var inputs = []
	for i in range(clamp(self.input_history.size() - history, 0, 100), self.input_history.size()):
		inputs.push_front(self.input_history[i])
	return inputs

func interpret_input(input: Dictionary, screen_position: String):
	
	var di = ""
	var button = ""

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

	match di:
		"N":
			di = Fighter.DI_STATE.NEUTRAL
		"U":
			di = Fighter.DI_STATE.UP
		"UF":
			di = Fighter.DI_STATE.UP_FORWARD
		"F":
			di = Fighter.DI_STATE.FORWARD
		"DF":
			di = Fighter.DI_STATE.DOWN_FORWARD
		"D":
			di = Fighter.DI_STATE.DOWN
		"DB":
			di = Fighter.DI_STATE.DOWN_BACK
		"B":
			di = Fighter.DI_STATE.BACK
		"UB":
			di = Fighter.DI_STATE.UP_BACK

	match button:
		"N":			
			button = Fighter.BUTTON_STATE.NONE
		"P":
			button = Fighter.BUTTON_STATE.P
		"K":
			button = Fighter.BUTTON_STATE.K
		"A":
			button = Fighter.BUTTON_STATE.A
		"PK":
			button = Fighter.BUTTON_STATE.PK
		"PA":
			button = Fighter.BUTTON_STATE.PA
		"KA":
			button = Fighter.BUTTON_STATE.KA
		"PKA":
			button = Fighter.BUTTON_STATE.PKA

	var current_input := {
			"di": di,
			"button": button, 
			"frame_start": SyncManager.current_tick,
			"screen_pos": screen_position
		}

	var last_input = self.input_history.back()
	if last_input == null:
		self.input_history.append(current_input)
		return
	
	if current_input["di"] != last_input["di"] || current_input["button"] != last_input["button"]:

		# add input to history
		self.input_history.append(current_input)

	# trim array if necessary
	if self.input_history.size() > 20:
		self.input_history.pop_front()
