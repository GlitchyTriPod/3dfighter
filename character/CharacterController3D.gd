extends Node3D
class_name CharacterController3D

var velocity := FixedVector3.new()

@onready var collision_body: FixedCollisionShape3d = self.get_node("Collision/FixedCollisionShape3d")

# Called when the node enters the scene tree for the first time.
# func _ready():
# 	pass # Replace with function body.


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass

func is_on_floor(stage: Stage) -> bool:
    return self.collision_body.is_on_floor(stage.floor_height)
	