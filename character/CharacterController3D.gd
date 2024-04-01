extends Node3D
class_name CharacterController3D

var velocity = FixedVector3.new()

@onready var collision_body: FixedCollisionShape3d = self.get_node("Collision/FixedCollisionShape3d")

# Called when the node enters the scene tree for the first time.
# func _ready():
# 	pass # Replace with function body.


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass

func is_on_floor(stage: Stage) -> bool:
    # get position of sphere
    # get radius of sphere
    # subtract radius from y position
    var rem = self.collision_body.fixed_position.y - self.collision_body.sphere_radius

    # if result is lower or equal to floor, return true
    return true if rem <= stage.floor_height else false
	