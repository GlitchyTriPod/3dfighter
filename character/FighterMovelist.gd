@tool
extends Resource
class_name FighterMovelist

@export var move_list: Dictionary = {}

enum BUTTON_FLAGS {
	P = 0x01,
	K = 0x02,
	A = 0x04
}

func add_to_list(move: FighterAnimationData) -> void:
	var key: String = str(self.move_list.size()) 
	self.move_list.get_or_add(key, move)

func add_arr_to_list(moves: Array[FighterAnimationData]) -> void:
	for i: FighterAnimationData in moves:
		self.add_to_list(i)

func get_default_anim_id_from_name(anim_name: String) -> String:
	for move_id: String in self.move_list:
		var move: FighterAnimationData = self.move_list[move_id]
		if anim_name == move.animation_name:
			return move_id
	return "0"

func get_from_id(move_id: String) -> FighterAnimationData:
	return self.move_list.get(move_id)

func get_move_id(move: FighterAnimationData) -> String:
	return self.move_list.find_key(move)

func get_from_ref_name(ref_name: String) -> Variant:
	for move_key: String in self.move_list:
		var move: FighterAnimationData = self.move_list[move_key]
		if !move.is_reference:
			continue
		if move.move_name == ref_name.substr(4):
			return move
	return false

func get_from_input(inputs: Array[Dictionary], player_states: PackedStringArray, screen_position: int) -> FighterAnimationData:
	var possible_moves: Array[FighterAnimationData] = []

	### selecting valid moves ###

	for move_key: String in self.move_list:
		var move: FighterAnimationData = self.move_list[move_key]

		if (move.input_di_map.back() == inputs[0]["di"] || \

			# this check is to specifically get neutral di input moves in the event there is no
			# move associated with the current di
			(move.input_di_map.size() == 1 && move.input_di_map[0] == 0))  && \

			self.is_valid_button_press(move.input_button, inputs[0]["button"]) && \
			(move.side_context == 0 || screen_position == move.side_context) && \
			(self.has_valid_states(move, player_states) if !move.required_state.is_empty() else true):
			
			# assert(move.move_name != "ground_wakeup_g_high")

			possible_moves.append(move)
	
	### determining move priority ###
	
	var temp_arr_state_moves: Array[FighterAnimationData] = possible_moves.filter(
		func(move: FighterAnimationData) -> bool:
			return !move.required_state.is_empty()
	)
	temp_arr_state_moves.sort_custom(
		func(a: FighterAnimationData, b: FighterAnimationData) -> bool:
			if a.required_state.split(", ").size() > b.required_state.split(", ").size():
				return true
			if a.input_button == b.input_button:
				return a.input_di_map[0] > b.input_di_map[0]
			return a.input_button > b.input_button
	)

	var temp_arr_motion_inputs: Array[FighterAnimationData] = possible_moves.filter(
		func(move: FighterAnimationData) -> bool:
			return move.input_di_map.size() > 1
	)
	temp_arr_motion_inputs.sort_custom(
		func(a: FighterAnimationData, b: FighterAnimationData) -> bool:
			if a.input_di_map.size() > b.input_di_map.size():
				return true
			if a.input_di_map.size() == b.input_di_map.size():
				return a.input_button > b.input_button
			return false
	)

	var temp_arr_normal_inputs: Array[FighterAnimationData] = possible_moves.filter(
		func(move: FighterAnimationData) -> bool:
			return move.input_di_map.size() <= 1
	)
	temp_arr_normal_inputs.sort_custom(
		func(a: FighterAnimationData, b: FighterAnimationData) -> bool:
			if a.input_button == b.input_button:
				return a.input_di_map[0] > b.input_di_map[0]
			return a.input_button > b.input_button
	)

	possible_moves = temp_arr_state_moves + temp_arr_motion_inputs + temp_arr_normal_inputs

	### selecting move ###

	for move: FighterAnimationData in possible_moves:
		# assert(!player_states.has("grounded"))

		# checking for motion input
		if move.input_di_map.size() > 1:
			if move.input_di_map.size() > inputs.size() || \
				SyncManager.current_tick - inputs[0].frame_start >= 6:
				continue
				

			# we already checked that the last part of the input matches, no need to recheck
			var passes_check: bool = true
			var di_map: Array = move.input_di_map.duplicate_deep()
			di_map.reverse()
											# vvv this allows for 1 entry on input leniency, input does not need to be frame perfect
			var input_history_offset: int = 1 if inputs[1]["di"] == di_map[0] else 0
			for i: int in range(1, di_map.size()):
				if di_map[i] != inputs[i + input_history_offset]["di"]:
					passes_check = false
					break

				if (inputs[i + input_history_offset - 1].frame_start \
					if i + input_history_offset - 1 >= 0 \
					else SyncManager.current_tick) \
					- inputs[i + input_history_offset].frame_start >= 6:
					
					passes_check = false
					break
				
			if passes_check == false:
				continue

			return move
			# break

		# move does not have a motion input
		return move
		# ...is that legit all it needs??? lol

	return self.move_list.get("0")

func is_valid_button_press(move_input: int, button_mask: int) -> bool:
	if ((move_input & BUTTON_FLAGS.P and button_mask & BUTTON_FLAGS.P) || \
		(move_input & BUTTON_FLAGS.K and button_mask & BUTTON_FLAGS.K) || \
		(move_input & BUTTON_FLAGS.A and button_mask & BUTTON_FLAGS.A) || \
		(move_input == 0 && button_mask == 0)) && \

		# this check makes sure that the selected move requires less or equal button presses than the actual input
		move_input <= button_mask:
		return true
	return false

func has_valid_states(move: FighterAnimationData, player_states: PackedStringArray) -> bool:

	var states: PackedStringArray = move.required_state.split(", ")
	var prohibited_states: PackedStringArray = move.prohibit_state.split(", ")
	var match_count: int = 0

	for state: String in prohibited_states:
		if player_states.has(state):
			return false

	for state: String in states:
		if player_states.has(state):
			match_count += 1
	
	return match_count >= states.size()
