@tool
extends Resource
class_name FighterMovelist

@export var move_list: Dictionary[StringName, FighterAnimationData] = {}

enum BUTTON_FLAGS {
	P = 0x01,
	K = 0x02,
	A = 0x04
}

var move_list_arr: Array[FighterAnimationData]

# func _init() -> void:
# 	if !Engine.is_editor_hint():
# 		self.create_and_sort_move_list_arr()

func add_to_list(move: FighterAnimationData, parent_key: StringName = &"") -> void:
	var key: StringName = StringName("%s_%d" % [parent_key, self.move_list.size()])
	if !move.extensions.is_empty():
		for extension: FighterAnimationData in move.extensions:
			extension.is_extension_only = true
			self.add_to_list(extension, key)
	self.move_list.get_or_add(key, move)

func add_arr_to_list(moves: Array[FighterAnimationData]) -> void:
	for i: FighterAnimationData in moves:
		self.add_to_list(i)

func create_and_sort_move_list_arr() -> void:
	self.move_list_arr = self.move_list.values()
	self.move_list_arr.sort_custom(
		func(a: FighterAnimationData, b: FighterAnimationData) -> bool:
			if (!a.required_state.is_empty() && b.required_state.is_empty()) || \
				a.required_state.size() > b.required_state.size():
				return true
			elif a.required_state.is_empty() && !b.required_state.is_empty():
				return false
			elif a.required_state.size() == b.required_state.size():
				if a.input_di_map.size() == b.input_di_map.size():
					if a.input_button == b.input_button:
						return a.input_di_map.get(a.input_di_map.size() - 1) > b.input_di_map.get(b.input_di_map.size() - 1)
					return a.input_button > b.input_button
				return a.input_di_map.size() >= b.input_di_map.size()
			return false
	)

func get_default_anim_id_from_name(anim_name: StringName) -> StringName:
	for move_id: StringName in self.move_list:
		var move: FighterAnimationData = self.move_list[move_id]
		if anim_name == move.animation_name:
			return move_id
	return &"_0"

func get_from_id(move_id: StringName) -> FighterAnimationData:
	return self.move_list.get(move_id)

func get_move_id(move: FighterAnimationData) -> StringName:
	return self.move_list.find_key(move)

func get_from_ref_name(ref_name: StringName) -> Variant:
	for move_key: StringName in self.move_list:
		var move: FighterAnimationData = self.move_list[move_key]
		if !move.is_reference:
			continue
		if move.move_name == ref_name.substr(4):
			return move
	return false

func get_from_input(inputs: Array[Dictionary], 
	player_states: PackedStringArray, 
	screen_position: int,
	bufferable: bool = false,
	extensions: Array[FighterAnimationData] = []
	) -> FighterAnimationData:

	if inputs[0][&"di"] == 7:
		pass

	# var possible_moves: Array[FighterAnimationData] = []

	### selecting valid moves ###

	for move: FighterAnimationData in self.move_list_arr if extensions.is_empty() else extensions:
		if (extensions.is_empty() && move.is_extension_only) || move.no_input:
			continue

		if (move.input_di_map.get(move.input_di_map.size() - 1) == inputs[0][&"di"] || \

			# this check is to specifically get neutral di input moves in the event there is no
			# move associated with the current di
			(move.input_di_map.size() == 1 && move.input_di_map[0] == 0))  && \

			self.is_valid_button_press(move.input_button, inputs[0][&"button"]) && \
			(move.side_context == 0 || screen_position == move.side_context) && \
			(self.has_valid_states(move, player_states, bufferable)):
			
			# possible_moves.append(move)

	### selecting move ###

			# for move: FighterAnimationData in possible_moves:
			# checking for motion input
			if move.input_di_map.size() > 1:
				if move.input_di_map.size() > inputs.size() || \
					SyncManager.current_tick - inputs[0].frame_start >= 6:
					continue
					
				# we already checked that the last part of the input matches, no need to recheck
				var passes_check: bool = true
				var di_map: Array = move.input_di_map.duplicate()
				di_map.reverse()
												# vvv this allows for 1 entry on input leniency, input does not need to be frame perfect
				var input_history_offset: int = 1 if inputs[1][&"di"] == di_map[0] else 0
				for i: int in range(1, di_map.size()):
					if i + input_history_offset >= di_map.size() || \
						di_map[i] != inputs[i + input_history_offset][&"di"]:
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

			# move does not have a motion input
			return move
			# ...is that legit all it needs??? lol
	return self.move_list.get(&"_0")

func is_valid_button_press(move_input: int, button_mask: int) -> bool:
	if move_input > button_mask || \
		(move_input & BUTTON_FLAGS.P && !(button_mask & BUTTON_FLAGS.P)) || \
		(move_input & BUTTON_FLAGS.K && !(button_mask & BUTTON_FLAGS.K)) || \
		(move_input & BUTTON_FLAGS.A && !(button_mask & BUTTON_FLAGS.A)):
		return false
	return true

func has_valid_states(move: FighterAnimationData, player_states: PackedStringArray, bufferable: bool) -> bool:
	if bufferable && move.non_bufferable:
		return false

	for state: String in move.prohibit_state:
		if player_states.has(state):
			return false

	var match_count: int = 0
	for state: String in move.required_state:
		if player_states.has(state):
			match_count += 1
	
	if move.move_name == &"walk_b":
		pass

	return match_count >= move.required_state.size()
