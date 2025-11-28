extends RefCounted
class_name FighterMessageBus

var player_1 : Fighter
var player_2 : Fighter
var game_camera : GameCamera

func get_char_position(player_global_position: Vector3) -> String:
	return self.game_camera.get_char_position(player_global_position)

func get_oppo_fixed_position(player: Fighter) -> FixedVector3:
	var oppo: Fighter
	if player == self.player_1:
		oppo = self.player_2
	else:
		oppo = self.player_1

	if oppo == null:
		return FixedVector3.new()

	return oppo.collision_body.fixed_position if oppo.collision_body != null \
		else FixedVector3.new()
