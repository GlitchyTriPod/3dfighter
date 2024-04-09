@tool
extends FixedCollisionShape3D
class_name FixedCharacterController3D


# Called when the node enters the scene tree for the first time.
# func _ready():
# 	super._ready()


func fixed_look_at(target: FixedVector3, axis: Vector3 = Vector3.UP):
	var ang := self.fixed_position.angle_to(target)
	print(float(FixedInt.rads2deg(ang)) / 65536.0)
	match axis:
		Vector3.FORWARD, Vector3.BACK:
			self.fixed_rotation.z = ang
		Vector3.UP, Vector3.DOWN:
			self.fixed_rotation.y = ang
		Vector3.LEFT, Vector3.RIGHT:
			self.fixed_rotation.x = ang
	
func is_on_floor(floor_height:int) -> bool:
	var res = super.is_on_floor(floor_height)
	if res:
		self.fixed_position.y = 32112
	return res
