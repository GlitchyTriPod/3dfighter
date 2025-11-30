# @tool
extends Resource
class_name FighterMovelist

# const uuid_util = preload("res://addons/uuid/uuid.gd")

var move_list : Dictionary[String, FighterAnimationData] = {}

# DEBUG TOOL ONLY
func _init() -> void:
	# if Engine.is_editor_hint():
	var debug_move = FighterAnimationData.new()
	debug_move.attack_name = "Jab"
	debug_move.animation_name = "atk_p_BAKED"

	debug_move.input_map.append(
		{
			"input_di": Fighter.DI_STATE.NEUTRAL,
			"input_button": Fighter.BUTTON_STATE.P
		}
	)

	debug_move.player_states = {
		"actionable": {
			"value": false,
			"frame_range": {
				"start": 0,
				"end": 26
			}
		}
	}

	self.add_to_list(debug_move)
	
	pass

func add_to_list(move: FighterAnimationData):
	var key = str(self.move_list.size()) #self.uuid_util.v4()
	self.move_list.get_or_add(key, move)

func get_from_input(_input_di: Fighter.DI_STATE, input_button: Fighter.BUTTON_STATE, _player_state: Dictionary) -> String:
	for move_id: String in self.move_list:
		var move: FighterAnimationData = self.move_list.get(move_id)

		# print(move.animation_name)
		if move.input_map[0].input_button == input_button: # <- need a more detailed selector, this is fine for now
			return move_id

	return "EMPTY"

func get_from_id(move_id: String) -> FighterAnimationData:
	return self.move_list.get(move_id)
