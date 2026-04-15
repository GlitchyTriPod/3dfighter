@tool
extends Resource
class_name FighterMovelist

# const uuid_util = preload("res://addons/uuid/uuid.gd")

@export var move_list: Dictionary = {}

# region DEBUG TOOL ONLY
# func _init() -> void:
# 	# if Engine.is_editor_hint():
# 	var debug_move = FighterAnimationData.new()
# 	debug_move.attack_name = "Jab"
# 	debug_move.animation_name = "atk_p_BAKED"

# 	debug_move.input_map.append(
# 		{
# 			"input_di": Fighter.DI_STATE.NEUTRAL,
# 			"input_button": Fighter.BUTTON_STATE.P
# 		}
# 	)

# 	debug_move.player_states = {
# 		"actionable": {
# 			"value": false,
# 			"frame_range": {
# 				"start": 0,
# 				"end": 26
# 			}
# 		}
# 	}

# 	debug_move.hitbox_data.append(
# 		{
# 			"attack_height": "high",
# 			"frame_range": {
# 				"start": 11,
# 				"end": 13
# 			},
# 			"pushback_hit": 0,
# 			"pushback_block": 0,
# 			"hit_anim": "hit_h_1_BAKED",
# 			"shapes": [
# 				{
# 					"radius": 12443,
# 					"position": FixedVector3.from_vec3(Vector3(-0.042, 1.333, 0.878))
# 				}
# 			]
# 		}
# 	)

# 	self.add_to_list(debug_move)
	
# endregion	pass

# func get_idle_anim() -> String:


func add_to_list(move: FighterAnimationData) -> void:
	var key: String = str(self.move_list.size()) 
	self.move_list.get_or_add(key, move)

func add_arr_to_list(moves: Array[FighterAnimationData]) -> void:
	for i: FighterAnimationData in moves:
		self.add_to_list(i)

func get_default_anim_id_from_name(anim_name: String) -> String:
	for move_id: String in self.move_list.keys():
		var move: FighterAnimationData = self.move_list.get(move_id)
		if anim_name.contains(move.move_name):
			return move_id
	return "0"

func get_from_id(move_id: String) -> FighterAnimationData:
	return self.move_list.get(move_id)

func get_from_ref_name(ref_name: String) -> Variant:
	for move: FighterAnimationData in self.move_list.values():
		if !move.is_reference:
			continue
		if move.move_name == ref_name:
			return move
	return false

func get_from_input(inputs: Array[Dictionary], player_states: Array[String], screen_position: int) -> FighterAnimationData:
	var ret_val: FighterAnimationData = null
	var possible_moves: Array[FighterAnimationData] = [ ]

	for move: FighterAnimationData in self.move_list.values():
		if move.input_di_map.back() == inputs[0]["di"] && \
			move.input_button == inputs[0]["button"] && \
			(move.side_context == 0 || screen_position == move.side_context):
			possible_moves.append(move)
	
	possible_moves.sort_custom(
		func(a: FighterAnimationData, b: FighterAnimationData) -> bool:
			if !a.required_state.is_empty() && player_states.has(a.required_state):
				return true
			if a.input_di_map.size() > b.input_di_map.size():
				return true
			return false
	)

	inputs.reverse()
	for move: FighterAnimationData in possible_moves:

		if move.input_di_map.size() > 1: # checking for motion input
			# we already checked that the last part of the input matches, no need to recheck
			var passes_check: bool = true
			for i: int in range(move.input_di_map.size() - 2, 0, -1):
				# make sure there are enough readable inputs for this move to be valid
				if (i >= inputs.size()) || \

					# check that directional input matches
					(move.input_di_map[i] != inputs[i]["di"]) || \

					# check that player input move quickly enough
					((inputs[i - 1].frame_start if i != 0 else SyncManager.current_tick) - inputs[i].frame_start > 6):

					passes_check = false
					break
				
			if passes_check == false:
				continue

			ret_val = move
			break

		# zzz

	return ret_val

	# # may need refactoring in order to improve search time. not making good use of move_list being a Dictionary
	# for move_id: String in self.move_list.keys():
	# 	var move: FighterAnimationData = self.move_list.get(move_id)

	# 	# print(move.animation_name)
	# 	if move.input_map[0].input_button == input_button: # <- need a more detailed selector, this is fine for now
	# 		return move_id

	# return "0"
