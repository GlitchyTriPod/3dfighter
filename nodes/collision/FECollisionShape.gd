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
