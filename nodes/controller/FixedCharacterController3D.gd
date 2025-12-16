@tool
extends FixedCollisionShape3D
class_name FixedCharacterController3D

func move_to_position(target:FixedVector3, y_offset: int = 0):
	self.fixed_position = target
	self.fixed_position.y += y_offset

func fixed_look_at(target: FixedVector3, axis: Vector3 = Vector3.UP):
	var ang := self.fixed_position.angle_to(target)
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
		self.fixed_position.y = self.sphere_radius
	return res
