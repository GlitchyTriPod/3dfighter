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

func _ready():
    if self.get_parent().player == 0:
        self.collision_body.add_to_group("Player1MainCollisionBody")
    else:        
        self.collision_body.add_to_group("Player2MainCollisionBody")

func is_on_floor(stage: Stage) -> bool:
    if self.collision_body == null:
        return false
    return self.collision_body.is_on_floor(stage.floor_height)
	
func collide_and_slide(delta:int):
    #worry about collision later, just focus on motion

    self.fixed_position.x += FixedInt.mul(self.velocity.x, delta)
    self.fixed_position.y += FixedInt.mul(self.velocity.y, delta)
    self.fixed_position.z += FixedInt.mul(self.velocity.z, delta)

    # check if collision body is intersecting with opponent's collision body
    var oppo: FixedCharacterController3D

    if self.collision_body.is_in_group("Player1MainCollisionBody"):
        var nde = get_tree().get_nodes_in_group("Player2MainCollisionBody")
        if nde.size() != 0:
            oppo = nde[0]
    else:
        var nde = get_tree().get_nodes_in_group("Player1MainCollisionBody")
        if nde.size() != 0:
            oppo = nde[0]

    if oppo == null: return

    var overlap = self.collision_body.fixed_is_overlapping_with(oppo)
    if overlap is int:
        print(overlap)
        var change := FixedVector3.mul(
            self.fixed_position.direction_to(oppo.fixed_position),
            FixedInt.div(overlap, FixedInt.FIXED_TWO)
        )

        self.fixed_position.x -= change.x
        # self.fixed_position.y -= change.y
        self.fixed_position.z -= change.z