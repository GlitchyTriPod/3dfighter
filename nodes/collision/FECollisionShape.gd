@tool
class_name FECollisionShape
extends ShapeCast3D

@export var fixed_sphere_radius := FixedInt.FIXED_HALF :
	set(val):
		fixed_sphere_radius = val
		if Engine.is_editor_hint():
			var sph = SphereShape3D.new()
			sph.radius = float(val / 65536.0)
			self.shape = sph

var fixed_position: FixedVector3:
	get:
		return FixedVector3.from_vec3(self.global_position)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.target_position = Vector3(0,0,0)
	if Engine.is_editor_hint():
		if self.shape == null:
			self.shape = SphereShape3D.new()
		else:
			self.shape = self.shape.duplicate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass

# Returns false if shapes are not overlapping. returns overlap distance if they are.
func fixed_is_overlapping_with(inc_shape: FECollisionShape) -> Variant:
	var combined_radius := FixedInt.mul(
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius), 
		(self.fixed_sphere_radius + inc_shape.fixed_sphere_radius)
	)
	var dist := self.fixed_position.distance_squared_to(inc_shape.fixed_position)
	if dist < combined_radius:
		return FixedInt.sqrt_64(combined_radius - dist)
	return false
