@tool
extends CollisionShape3D
class_name FixedCollisionShape3D

@export var exp_fixed_position := FixedVector3.new()
@export var exp_fixed_rotation := FixedVector3.new()

@onready var fixed_position: FixedVector3
@onready var fixed_rotation: FixedVector3
# @export var fixed_velocity := FixedVector3.new()

# Use Fixed-point math. (float value * 65536, drop remainder)
@export var sphere_radius: int = 32768: # <-- 0.5 * 65536
	set(val):
		sphere_radius = val
		self.shape.radius = float(sphere_radius) / 65536.0

@export var margin: int = 2621: # 0.04 * 65536
	set(val):
		margin = val
		self.shape.margin = float(margin) / 65536.0

# Called when the node enters the scene tree for the first time.
func _ready():
	self.fixed_position = FixedVector3.new(
			self.exp_fixed_position.x,
			self.exp_fixed_position.y,
			self.exp_fixed_position.z
	)
	self.fixed_rotation = FixedVector3.new(
			self.exp_fixed_rotation.x,
			self.exp_fixed_rotation.y,
			self.exp_fixed_rotation.z
	)


	self.shape = SphereShape3D.new()
	self.sphere_radius = self.sphere_radius

	# to be clear, all of this is for hitbox visualizations. has nothing to do with collision detection
	self.fixed_position.universal_setter_callback = func():
		self.position.x = float(self.fixed_position.x) / 65536.0
		self.position.y = float(self.fixed_position.y) / 65536.0
		self.position.z = float(self.fixed_position.z) / 65536.0
	self.fixed_position.universal_setter_callback.call()

	self.fixed_rotation.universal_setter_callback = func():
		self.rotation.x = float(self.fixed_rotation.x / 65536.0)
		self.rotation.y = float(self.fixed_rotation.y / 65536.0)
		self.rotation.z = float(self.fixed_rotation.z / 65536.0)
	self.fixed_rotation.universal_setter_callback.call()


#should only run in editor
func _notification(what: int):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		#position
		self.exp_fixed_position.x = int(self.position.x * 65536)
		self.exp_fixed_position.y = int(self.position.y * 65536)
		self.exp_fixed_position.z = int(self.position.z * 65536)

		#rotation
		self.exp_fixed_rotation.x = int(self.rotation.x * 65536)
		self.exp_fixed_rotation.y = int(self.rotation.y * 65536)
		self.exp_fixed_rotation.z = int(self.rotation.z * 65536)

# called by charactercontroller3d
func is_on_floor(floor_height: int) -> bool:
	var rem = self.fixed_position.y - self.sphere_radius
	return true if rem <= floor_height else false