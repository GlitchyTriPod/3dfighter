extends Node3D
class_name Stage

@onready var char_container: Node3D = %Chars

@onready var post_processing_node = $PostProcessing

# Called when the node enters the scene tree for the first time.
func _ready():
	if self.post_processing_node != null:
		self.post_processing_node.visible = true

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass