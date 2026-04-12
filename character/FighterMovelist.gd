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

func get_from_input(_input_di: Fighter.DI_STATE, input_button: Fighter.BUTTON_STATE, _player_state: Array) -> String:
	# may need refactoring in order to improve search time. not making good use of move_list being a Dictionary
	for move_id: String in self.move_list.keys():
		var move: FighterAnimationData = self.move_list.get(move_id)

		# print(move.animation_name)
		if move.input_map[0].input_button == input_button: # <- need a more detailed selector, this is fine for now
			return move_id

	return "0"

func get_from_id(move_id: String) -> FighterAnimationData:
	return self.move_list.get(move_id)
