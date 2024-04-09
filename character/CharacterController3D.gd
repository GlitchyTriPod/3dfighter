extends Node3D
class_name CharacterController3D

var velocity := FixedVector3.new():
    set(val):
        velocity.x = val.x
        velocity.y = val.y
        velocity.z = val.z

@onready var collision_body: FixedCharacterController3D = self.get_node("Collision/FixedCharacterController3D")

var fixed_position: FixedVector3:
    get:
        if self.collision_body != null:
            return self.collision_body.fixed_position
        return FixedVector3.new()

var fixed_rotation: FixedVector3:
    get:
        if self.collision_body != null:
            return self.collision_body.fixed_rotation
        return FixedVector3.new()


func is_on_floor(stage: Stage) -> bool:
    if self.collision_body == null:
        return false
    return self.collision_body.is_on_floor(stage.floor_height)
	
func collide_and_slide(delta:int):
    #worry about collision later, just focus on motion

    self.fixed_position.x += FixedInt.mul(self.velocity.x, delta)
    self.fixed_position.y += FixedInt.mul(self.velocity.y, delta)
    self.fixed_position.z += FixedInt.mul(self.velocity.z, delta)