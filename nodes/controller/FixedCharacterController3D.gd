@tool
extends FixedCollisionShape3D
class_name FixedCharacterController3D


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()


func fixed_look_at(target: FixedVector3):
	pass