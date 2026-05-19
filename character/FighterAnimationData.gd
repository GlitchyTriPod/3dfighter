@tool
extends Resource
class_name FighterAnimationData

enum BUTTON_FLAGS {
	P = 0x01,
	K = 0x02,
	A = 0x04
}

@export_storage var move_name: String = ""
@export_storage var move_type: int = 0

@export_storage var is_reference: bool
@export_storage var is_extension_only: bool = false

@export_storage var input_di_map: Array = []
@export_storage var input_button: int

@export_storage var animation_name: String = ""

@export_storage var animation_length: int

@export_storage var required_state: String = ""
@export_storage var prohibit_state: String = ""

@export_storage var no_input: bool = false
@export_storage var hold_input: bool = false
@export_storage var non_attack: bool = false
@export_storage var non_bufferable: bool = false

@export_storage var attack_speed: int

@export_storage var recovery_hit: String = ""
@export_storage var has_hit_recovery: bool = false

@export_storage var recovery_ch: String = ""
@export_storage var has_ch_recovery: bool = false

@export_storage var recovery_block: String = ""
@export_storage var has_block_recovery: bool = false

@export_storage var unblockable: bool
@export_storage var is_grab: bool
@export_storage var is_punch: bool
@export_storage var is_kick: bool

@export_storage var recovery_ref: String
@export_storage var hit_animation: String
@export_storage var block_animation: String
@export_storage var crouch_block_animation: String = ""
@export_storage var has_crouch_block_property: bool = false
@export_storage var counter_animation: String = ""
@export_storage var has_counter_property: bool = false
@export_storage var air_hit_animation: String = ""
@export_storage var ground_hit_animation: String = ""
@export_storage var back_hit_animation: String = ""

@export_storage var face_attacker_on_hit: bool = false

# contains data on any hitboxes put out by the animation.
# Keep empty if this animation does not attack the opponent
@export_storage var hitbox_data: Dictionary = {}

# contains data on misc. hurtboxes that extends the player's hit area
@export_storage var hurtbox_data: Dictionary = {}

# contains fighter state data based on frame ranges
@export_storage var player_states: Dictionary = {}

@export_storage var pushback_force: int
@export_storage var pushback_direction: int
@export_storage var launch_force: int
@export_storage var launch_direction: int

@export_storage var pushback_mod_on_hit: int = 0
@export_storage var pushback_mod_on_counter: int = 0
@export_storage var pushback_mod_on_ground_hit: int = 0
@export_storage var pushback_mod_on_block: int = 0

@export_storage var pushback_angle_on_hit: bool = true
@export_storage var pushback_angle_on_counter: bool = true
@export_storage var pushback_angle_on_ground_hit: bool = true
@export_storage var pushback_angle_on_block: bool = true

@export_storage var extension_buffer_start: int = -1
@export_storage var extension_execute_start: int = -1
@export_storage var extension_execute_end: int = -1

@export_storage var extensions: Array[FighterAnimationData] = []

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

func extension_possible(anim_position: float, check_buffer: bool = false) -> bool:
    if self.extensions.is_empty():
        return false

    var current_frame: int = floori(anim_position * 60)
    if check_buffer:
        if current_frame >= self.extension_buffer_start && current_frame < self.extension_execute_end:
            return true
    else:
        if current_frame >= self.extension_execute_start && current_frame < self.extension_execute_end:
            return true

    return false