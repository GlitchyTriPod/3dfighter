extends Node
class_name InputInterpreter_old
@onready var fighter = get_parent()

var input_history: Array = []

func read_input(history := 0) -> Array:
	if history == 0:
		return [self.input_history.back()] # temp
	var inputs = []
	for i in range(clamp(self.input_history.size() - history, 0, 100), self.input_history.size()):
		inputs.push_front(self.input_history[i])
	return inputs

func interpret_input(input: Array[String]):

	var di = ""
	var button = ""

	# socd cleaning
	if input.has("up") && input.has("down"):
		input.erase("up")
		input.erase("down")
	if input.has("left") && input.has("right"):
		input.erase("left")
		input.erase("right")

	# check directional input
	if input.has("down"): di += "D"
	elif input.has("up"): di += "U"
	if input.has("left"):
		if self.fighter.screen_position == "LEFT": # flip B<->F based on screen position
			di += "B"
		else: di += "F"
	elif input.has("right"):
		if self.fighter.screen_position == "LEFT":
			di += "F"
		else: di += "B"
	elif di == "": di += "N"
	
	# check button inputs
	if input.has("p"): button += "P"
	if input.has("k"): button += "K"
	if input.has("a"): button += "A"
	elif button == "": button += "N"

	match di:
		"N":
			di = FEFighter.DI_STATE.NEUTRAL
		"U":
			di = FEFighter.DI_STATE.UP
		"UF":
			di = FEFighter.DI_STATE.UP_FORWARD
		"F":
			di = FEFighter.DI_STATE.FORWARD
		"DF":
			di = FEFighter.DI_STATE.DOWN_FORWARD
		"D":
			di = FEFighter.DI_STATE.DOWN
		"DB":
			di = FEFighter.DI_STATE.DOWN_BACK
		"B":
			di = FEFighter.DI_STATE.BACK
		"UB":
			di = FEFighter.DI_STATE.UP_BACK

	match button:
		"N":			
			button = FEFighter.BUTTON_STATE.NONE
		"P":
			button = FEFighter.BUTTON_STATE.P
		"K":
			button = FEFighter.BUTTON_STATE.K
		"A":
			button = FEFighter.BUTTON_STATE.A
		"PK":
			button = FEFighter.BUTTON_STATE.PK
		"PA":
			button = FEFighter.BUTTON_STATE.PA
		"KA":
			button = FEFighter.BUTTON_STATE.KA
		"PKA":
			button = FEFighter.BUTTON_STATE.PKA

	# if input history is empty, enter current frame in.
	if self.input_history.is_empty():
		self.input_history.append({"di": di, "button": button, "frame_count": 1, "screen_pos": self.fighter.screen_position})
		return
	
	# check current input against the previous frame's
	var last_frame = self.input_history.back()
	if last_frame.di == di && last_frame.button == button: # if matching input, increase frame counter
		last_frame.frame_count += 1
		if last_frame.frame_count > 999: last_frame.frame_count = 999
		return

	# add input to history
	self.input_history.append({"di": di, "button": button, "frame_count": 1, "screen_pos": self.fighter.screen_position})
