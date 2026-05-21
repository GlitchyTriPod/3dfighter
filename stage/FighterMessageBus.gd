extends RefCounted
class_name FighterMessageBus

var player_1 : Fighter
var player_2 : Fighter
var game_camera : GameCamera

func get_oppo_current_animation_data(player: Fighter, id: StringName) -> FighterAnimationData:
	var oppo: Fighter
	if player == self.player_1:
		oppo = self.player_2
	else:
		oppo = self.player_1
	return oppo.movelist.get_from_id(id)
	
func get_oppo_current_animation_id(player: Fighter) -> StringName:
	var oppo: Fighter
	if player == self.player_1:
		oppo = self.player_2
	else:
		oppo = self.player_1
	return oppo.current_anim_id

func get_oppo_states(player: Fighter) -> PackedStringArray:
	if player == self.player_1:
		return self.player_2.states
	return self.player_1.states

func get_oppo_hitboxes(player: Fighter) -> Array:
	if player == self.player_1:
		return self.player_2.misc_hitbox_pool
	return self.player_1.misc_hitbox_pool

func get_oppo_collision_body(player: Fighter) -> FEFighterCollisionBody:
	var oppo: Fighter
	if player == self.player_1:
		oppo = self.player_2
	else:
		oppo = self.player_1
	return oppo.collision_body

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

func get_oppo_fixed_rotation(player: Fighter) -> FixedVector3:
	var oppo: Fighter
	if player == self.player_1:
		oppo = self.player_2
	else:
		oppo = self.player_1

	if oppo == null:
		return FixedVector3.new()

	return oppo.collision_body.fixed_rotation if oppo.collision_body != null \
		else FixedVector3.new()

func get_char_position(player: int) -> int:
	return self.game_camera.get_char_position(player)	