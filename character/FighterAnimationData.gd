extends WeakRef
class_name FighterAnimationData

# var id: String

var move_name: String = ""

var input_di_map: Array = []
var input_button: int

var animation_name: String = ""

var animation_length: int

var attack_speed: int

var recovery_hit: int
var recovery_block: int
var recovery_counter: int

# contains data on any hitboxes put out by the animation.
# Keep empty if this animation does not attack the opponent
var hitbox_data: Dictionary = {}

# contains data on misc. hurtboxes that extends the player's hit area
var hurtbox_data: Dictionary = {}

# contains fighter state data based on frame ranges
var player_states: Dictionary = {}

# TODO: link to other AnimationData to enable attack strings

func add_inputs_arr(inputs: Array):
    self.input_di_map = inputs.slice(-1, inputs.size() - 2)
    self.input_button = inputs[inputs.size() -1]