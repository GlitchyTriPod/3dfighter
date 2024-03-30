
extends Node3D
class_name Character

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var char_controller: CharacterBody3D = %CharacterBody3D

func _process(_delta):
	pass
	if Input.is_action_pressed("INPUT_LEFT"):
		self.char_controller.velocity.x = 3
	
	elif Input.is_action_pressed("INPUT_RIGHT"):
		self.char_controller.velocity.x = -3
	else:
		self.char_controller.velocity.x = 0

func _physics_process(delta):
	# Add the gravity.
	if not self.char_controller.is_on_floor():
		self.char_controller.velocity.y -= gravity * delta

	# Handle Jump.
	# if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	# 	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	# var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# if direction:
	# 	velocity.x = direction.x * SPEED
	# 	velocity.z = direction.z * SPEED
	# else:
	# 	velocity.x = move_toward(velocity.x, 0, SPEED)
	# 	velocity.z = move_toward(velocity.z, 0, SPEED)

	self.char_controller.move_and_slide()
