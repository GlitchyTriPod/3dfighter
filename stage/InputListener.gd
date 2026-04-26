extends Node
class_name InputListener

@onready var player_1: Fighter = get_node("../Chars").get_child(0)
@onready var player_2: Fighter = get_node("../Chars").get_child(1)

var is_p1_local : bool = true
var is_p2_local : bool = true

var is_online_match : bool = false

# # Called every network tick.
func _network_process(_input: Dictionary) -> void:

	var _delta_int: int = FixedInt.from_float(SyncManager.tick_time)

	# set player states based on animation data
	self.player_1.process_animation_data()
	self.player_2.process_animation_data()

	# enable/disable hit/hurtboxes for player based on anim data
	self.player_1.process_animation_hitboxes()
	self.player_2.process_animation_hitboxes()

	# check for hit/hurtbox intersections
	self.player_1.process_hitbox_intersection()
	self.player_2.process_hitbox_intersection()

	#advance player animations based on inputs & game state
	self.player_1.process_movement(_delta_int)
	self.player_2.process_movement(_delta_int)

