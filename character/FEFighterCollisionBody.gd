@tool
class_name FEFighterCollisionBody
extends FECollisionShape

# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	if self.get_parent().player == 0:
		self.add_to_group("Player1MainCollisionBody")
	else:
		self.add_to_group("Player2MainCollisionBody")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass

func is_on_floor(floor_height: int) -> bool:
	var rem = self.fixed_position.y - self.fixed_sphere_radius
	return rem <= floor_height
