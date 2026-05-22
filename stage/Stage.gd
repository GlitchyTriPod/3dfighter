extends Node3D
class_name Stage

@onready var char_container: Node3D = get_node("Chars")
@onready var game_camera: GameCamera = get_node("GameCamera")
# @onready var post_processing_node = $PostProcessing
@onready var input_listener: InputListener = $InputListener

var fighter_message_bus: FighterMessageBus = FighterMessageBus.new()

# use fixed-point math. change this value if needed, but default should be fine unless youre doing something fancy
@export var floor_height: int = 0

var is_online_match: bool = false

var player_1_peer_id: int
var player_2_peer_id: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# if self.post_processing_node != null:
	# 	self.post_processing_node.visible = true

	self.fighter_message_bus.game_camera = self.game_camera

	for c: Fighter in char_container.get_children():
		# c.stage = self
		c.message_bus = self.fighter_message_bus
		c.floor_height = self.floor_height
		if c.player == 1:
			self.fighter_message_bus.player_1 = c
			self.game_camera.player_1 = c
			continue
		self.fighter_message_bus.player_2 = c
		self.game_camera.player_2 = c

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	StageGarbageCollection.CollectGarbage()