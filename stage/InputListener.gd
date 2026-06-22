extends Node
class_name InputListener

@onready var player_1: Fighter = get_node("../Chars").get_child(0)
@onready var player_2: Fighter = get_node("../Chars").get_child(1)

var is_p1_local: bool = true
var is_p2_local: bool = true

var is_online_match : bool = false

@onready var _delta_int: int = FixedInt.FromFloat(SyncManager.tick_time)

func _network_preprocess(_input: Dictionary) -> void:
	var stage: Stage = self.get_parent()

	var wall_data: Dictionary[StringName, Variant] = \
		stage.get_player_wall_influence(
			self.player_1.collision_body.fixed_position,
			self.player_2.collision_body.fixed_position
		)

	self.player_1.wall_ids = wall_data[&"p1"][&"wall_ids"]
	self.player_1.wall_normal = wall_data[&"p1"][&"normal"]
	self.player_2.wall_ids = wall_data[&"p2"][&"wall_ids"]
	self.player_2.wall_normal = wall_data[&"p2"][&"normal"]	

# Called every network tick.
func _network_process(_input: Dictionary) -> void:

	if self._delta_int == 0:
		self._delta_int = FixedInt.FromFloat(SyncManager.tick_time)

	# set player states based on animation data
	self.player_1.process_animation_data()
	self.player_2.process_animation_data()

	# set player states based on calculations
	self.player_1.process_calculated_states()
	self.player_2.process_calculated_states()

	# enable/disable hit/hurtboxes for player based on anim data
	self.player_1.process_animation_hitboxes()
	self.player_2.process_animation_hitboxes()

	# check for hit/hurtbox intersections
	var p1_blocked: bool = self.player_1.process_hitbox_intersection()
	var p2_blocked: bool = self.player_2.process_hitbox_intersection()

	#advance player animations based on inputs & game state
	self.player_1.process_movement(self._delta_int, p2_blocked)
	self.player_2.process_movement(self._delta_int, p1_blocked)
