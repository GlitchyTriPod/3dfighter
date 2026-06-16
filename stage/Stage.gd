@tool
extends Node3D
class_name Stage

@onready var char_container: Node3D = get_node("Chars")
@onready var game_camera: GameCamera = get_node("GameCamera")
# @onready var post_processing_node = $PostProcessing
@onready var input_listener: InputListener = $InputListener

# use fixed-point math. change this value if needed, but default should be fine unless youre doing something fancy
@export var floor_height: int = 0

@export_tool_button("Generate Stage Bounds") var stage_bounds_button: Callable = generate_stage_bounds
@export var stage_bounds: Array[Dictionary]
@export_tool_button("Update Bound Normals Display") var bound_normals_button: Callable = update_stage_bound_normals

var fighter_message_bus: FighterMessageBus = FighterMessageBus.new()

var is_online_match: bool = false

var player_1_peer_id: int
var player_2_peer_id: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	%Debug.queue_free()

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

	self.fighter_message_bus.assign_fighter_look_at_targets()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !Engine.is_editor_hint():
		StageGarbageCollection.CollectGarbage()
		return



# ============ EDITOR FUNCTIONS ===============

# TODO: add support for multiple stage bound shapes for freestanding objects within a stage
func generate_stage_bounds() -> void:
	self.stage_bounds.clear()

	for i: int in %StageBounds.polygon.size():
		var start: Vector2 =  %StageBounds.polygon[i]
		var end: Vector2 = %StageBounds.polygon[i + 1] if !(i + 1 >= %StageBounds.polygon.size()) else %StageBounds.polygon[0]

		var entry: Dictionary[StringName, Variant] = {
			&"start": {
				&"x": FixedInt.FromFloat(start.x),
				&"z": FixedInt.FromFloat(start.y),
			},
			&"end": {
				&"x": FixedInt.FromFloat(end.x),
				&"z": FixedInt.FromFloat(end.y)
			},
			&"x_positive": true,
			&"z_positive": true
		}

		self.stage_bounds.append(entry)

func update_stage_bound_normals() -> void:
	for nde: Node in %Debug.get_children():
		nde.queue_free()

	for entry: Dictionary in self.stage_bounds:
		var ray: RayCast3D = RayCast3D.new()

		ray.debug_shape_thickness = 10
		ray.debug_shape_custom_color = Color.MAGENTA

		ray.position.x = (FixedInt.ToFloat(entry[&"start"][&"x"]) + FixedInt.ToFloat(entry[&"end"][&"x"])) / 2
		ray.position.y = 2.0
		ray.position.z = (FixedInt.ToFloat(entry[&"start"][&"z"]) + FixedInt.ToFloat(entry[&"end"][&"z"])) / 2

		ray.target_position.x = FixedInt.ToFloat(entry[&"end"][&"z"]) - FixedInt.ToFloat(entry[&"start"][&"z"])
		ray.target_position.y = 0.0 
		ray.target_position.z = FixedInt.ToFloat(entry[&"end"][&"x"]) - FixedInt.ToFloat(entry[&"start"][&"x"])

		ray.target_position = ray.target_position.normalized() * 3

		if entry[&"x_positive"]:
			ray.target_position.x = absf(ray.target_position.x)
		else:
			ray.target_position.x = -absf(ray.target_position.x)
		if entry[&"z_positive"]:
			ray.target_position.z = absf(ray.target_position.z)
		else:
			ray.target_position.z = -absf(ray.target_position.z)

		%Debug.add_child(ray)
		ray.owner = EditorInterface.get_edited_scene_root()