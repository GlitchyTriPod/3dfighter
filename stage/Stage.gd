extends Node3D
class_name Stage

@onready var char_container: Node3D = %Chars

@onready var post_processing_node = $PostProcessing

# use fixed-point math. change this value if needed, but default should be fine unless youre doing something fancy
@export var floor_height: int = 0



# Called when the node enters the scene tree for the first time.
func _ready():
	if self.post_processing_node != null:
		self.post_processing_node.visible = true

	for c: Fighter in char_container.get_children():
		c.stage = self
		if c.name == "Fighter2":
			c.player = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(_delta):
# 	pass