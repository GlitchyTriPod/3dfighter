@tool
extends Resource
class_name FighterAnimationData

enum BUTTON_FLAGS {
	P = 0x01,
	K = 0x02,
	A = 0x04
}

@export var move_name: String = ""
@export var move_type: int = 0

@export var input_di_map: Array = []
@export var input_button: int

@export var animation_name: String = ""

@export var animation_length: int

@export var required_state: String = ""
@export var prohibit_state: String = ""

@export var non_attack: bool = false

@export var attack_speed: int

@export var recovery_hit: String = ""
@export var has_hit_recovery: bool = false

@export var recovery_ch: String = ""
@export var has_ch_recovery: bool = false

@export var recovery_block: String = ""
@export var has_block_recovery: bool = false

@export var unblockable: bool
@export var is_grab: bool
@export var is_punch: bool
@export var is_kick: bool

@export var hit_animation: String
@export var block_animation: String
@export var crouch_block_animation: String = ""
@export var has_crouch_block_property: bool = false
@export var counter_animation: String = ""
@export var has_counter_property: bool = false
@export var air_hit_animation: String = ""
@export var ground_hit_animation: String = ""
@export var back_hit_animation: String = ""

@export var face_attacker_on_hit: bool = false

@export var pushback_force: int
@export var pushback_direction: int
@export var launch_force: int
@export var launch_direction: int

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

    var button_val: int = 0
    if inputs[inputs.size() - 1].contains("P"):
        button_val |= BUTTON_FLAGS.P
    if inputs[inputs.size() - 1].contains("K"):
        button_val |= BUTTON_FLAGS.K
    if inputs[inputs.size() - 1].contains("A"):
        button_val |= BUTTON_FLAGS.A

    self.input_button = button_val