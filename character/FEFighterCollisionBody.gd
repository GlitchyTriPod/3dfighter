@tool
extends FECollisionShape
class_name FEFighterCollisionBody

var pushback_force: int = 0

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
    var rem: int = self.fixed_position.y - self.fixed_sphere_radius
    return rem <= floor_height

func fixed_look_at(
    target: FixedVector3, 
    axis: FixedVector3, 
    invert: bool = false,
    lerp_rotation: bool = false, 
    delta: int = 0) -> void:
    var forward: FixedVector3 
    if invert:
        forward = FixedVector3.Sub(self.fixed_position, target)
    else:
        forward = FixedVector3.Sub(target, self.fixed_position)

    var fixed_lookat_basis: Array = FixedVector3.BasisLookingAt(forward, axis, true)
    var final_rotation: FixedVector3 = FixedVector3.BasisGetEuler(fixed_lookat_basis)
    
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

func get_look_at(target: FixedVector3, axis: FixedVector3) -> FixedVector3:
    var forward: FixedVector3 = FixedVector3.Sub(target, self.fixed_position)
    var fixed_lookat_basis: Array = FixedVector3.BasisLookingAt(forward, axis, true)
    return FixedVector3.BasisGetEuler(fixed_lookat_basis)

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
