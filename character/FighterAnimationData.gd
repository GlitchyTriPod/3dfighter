@tool
extends Resource
class_name FighterAnimationData

# var id: String

@export var move_name: String = ""

@export var input_di_map: Array = []
@export var input_button: int

@export var animation_name: String = ""

@export var animation_length: int

@export var required_state: String = ""

@export var attack_speed: int

@export var recovery_hit: int
@export var recovery_block: int
@export var recovery_counter: int

@export var unblockable: bool
@export var is_grab: bool
@export var is_punch: bool
@export var is_kick: bool

@export var hit_animation: String
@export var block_animation: String

@export var pushback_force: int

# contains data on any hitboxes put out by the animation.
# Keep empty if this animation does not attack the opponent
@export var hitbox_data: Dictionary = {}

# contains data on misc. hurtboxes that extends the player's hit area
@export var hurtbox_data: Dictionary = {}

# contains fighter state data based on frame ranges
@export var player_states: Dictionary = {}

# TODO: link to other AnimationData to enable attack strings
@export var is_reference: bool
@export var recovery_ref: String

@export var no_input: bool = false
@export var hold_input: bool = false

@export_enum("Both", "Left", "Right") var side_context: int = 0

func add_inputs_arr(inputs: Array) -> void:
    self.input_di_map = inputs.slice(0, inputs.size() - 1)
    self.input_button = inputs[inputs.size() -1]