@tool
extends Resource
class_name FECollisionData

enum BODY_PART {
    NONE,
    HEAD,
    TORSO,
    WAIST,
    ARM_L,
    ARM_R,
    HAND_L,
    HAND_R,
    LEG_L,
    LEG_R,
    FOOT_L,
    FOOT_R
}

var fixed_sphere_radius: int = FixedIntGDConstant.FIXED_HALF

var body_part: int = BODY_PART.NONE

var is_hitbox: bool = false

# used to detect individual hit instances in multi-hit moves
var hitbox_attack_index: int = -1
var hitbox_attack_name: String = ""

var fixed_position: FixedVector3
var fixed_rotation: FixedVector3

var enabled: bool = false

func fixed_is_overlapping_with(inc_shape: FECollisionData) -> Variant:
    var combined_radius: int = FixedInt.Mul(
        (self.fixed_sphere_radius + inc_shape.fixed_sphere_radius), 
        (self.fixed_sphere_radius + inc_shape.fixed_sphere_radius)
    )
    var dist: int = self.fixed_position.DistanceSquaredTo(inc_shape.fixed_position)
    if dist < combined_radius:
        return FixedInt.Sqrt64(combined_radius - dist)
    return false