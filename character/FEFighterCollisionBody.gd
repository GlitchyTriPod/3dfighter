@tool
extends FECollisionShape
class_name FEFighterCollisionBody

var pushback_force: int = 0
var pushback_angle: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    super()
    self.debug_shape_custom_color = Color.GREEN

    if self.get_parent().player == 0:
        self.add_to_group("Player1MainCollisionBody")
    else:
        self.add_to_group("Player2MainCollisionBody")

    self.add_to_group("network_sync")

func _process(_delta: float) -> void:
    if !Engine.is_editor_hint():
        self.debug_shape_custom_color = Color.GREEN


func is_on_floor(floor_height: int) -> bool:
    var rem: int = self.fixed_position.y - FixedIntGDConstant.FIXED_HALF #self.fixed_sphere_radius
    return rem <= floor_height


func fixed_look_at(
    target: FixedVector3,
    invert: bool = false,
    lerp_rotation: bool = false, 
    delta: int = 0,
    use_zero_y: bool = false) -> void:

    # for some reason the alignment gets strange when origin and target are not on same y position.
    var zero_y_pos: FixedVector3 = FixedVector3.NewFromInt(self.fixed_position.x, 0, self.fixed_position.z)
    var zero_y_target: FixedVector3 = FixedVector3.NewFromInt(target.x, 0, target.z)

    var forward: FixedVector3 
    if invert:
        if use_zero_y:
            forward = FixedVector3.Sub(zero_y_pos, zero_y_target)
        else:
            forward = FixedVector3.Sub(self.fixed_position, target)
    else:
        if use_zero_y:
            forward = FixedVector3.Sub(zero_y_target, zero_y_pos)
        else:
            forward = FixedVector3.Sub(target, self.fixed_position)

    var final_rotation: FixedVector3 = FixedVector3.BasisGetEuler(forward, true)
    
    if lerp_rotation:
        self.fixed_rotation = FixedVector3.Lerp(
            self.fixed_rotation, 
            final_rotation,
            FixedInt.Mul(FixedInt.FromFloat(1.5), delta)
        )
    else:
        self.fixed_rotation = final_rotation

    if self.fixed_rotation.x != FixedIntGDConstant.FIXED_ZERO:
        self.fixed_rotation.x = FixedIntGDConstant.FIXED_ZERO
    if self.fixed_rotation.z != FixedIntGDConstant.FIXED_ZERO:
        self.fixed_rotation.z = FixedIntGDConstant.FIXED_ZERO

func get_look_at(target: FixedVector3) -> FixedVector3:
    var zero_y_pos: FixedVector3 = FixedVector3.NewFromInt(self.fixed_position.x, 0, self.fixed_position.z)
    var zero_y_target: FixedVector3 = FixedVector3.NewFromInt(target.x, 0, target.z)
    # var forward: FixedVector3 = FixedVector3.Sub(target, self.fixed_position)
    var forward: FixedVector3 = FixedVector3.Sub(zero_y_target, zero_y_pos)
    return FixedVector3.BasisGetEuler(forward, true)

func _save_state() -> Dictionary:
    return {
        "position": {
            "x": self.fixed_position.x,
            "y": self.fixed_position.y,
            "z": self.fixed_position.z
        },
        # # self.fixed_position,
        "rotation": {
            "x": self.fixed_rotation.x,
            "y": self.fixed_rotation.y,
            "z": self.fixed_rotation.z
        },
        # "rotation": self.fixed_rotation,
        "velocity": {
            "x": self.velocity.x,
            "y": self.velocity.y,
            "z": self.velocity.z
        },
        # "velocity": self.velocity
        "enabled": self.enabled,
        "sphere_radius": self.fixed_sphere_radius
    }

func _load_state(state: Dictionary) -> void:
    self.fixed_position = FixedVector3.NewFromInt(
        state.position.x,
        state.position.y,
        state.position.z
    )
    self.fixed_rotation = FixedVector3.NewFromInt(
        state.rotation.x,
        state.rotation.y,
        state.rotation.z
    )
    self.velocity = FixedVector3.NewFromInt(
        state.velocity.x,
        state.velocity.y,
        state.velocity.z
    )
    self.enabled = state.enabled
    self.fixed_sphere_radius = state.sphere_radius
