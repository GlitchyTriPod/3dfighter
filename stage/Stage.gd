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
@export_storage var stage_wall_detection_areas: Array[Dictionary]
@export_tool_button("Update Wall Detection Areas") var wall_detection_button: Callable = update_wall_detection_areas

var fighter_message_bus: FighterMessageBus = FighterMessageBus.new()

var is_online_match: bool = false
var allow_neutral_guard: bool = false

var player_1_peer_id: int
var player_2_peer_id: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	%Debug.queue_free()

	self.fighter_message_bus.game_camera = self.game_camera
	self.fighter_message_bus.stage_bounds = self.stage_bounds

	for c: Fighter in char_container.get_children():
		# c.stage = self
		c.neutral_guard_active = self.allow_neutral_guard
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

# ============ GAME FUNCTIONS =================

# Checks the player location against the stage's wall areas, and returns the wall ids & combined normal
func get_player_wall_influence(p1_loc: FixedVector3, p2_loc: FixedVector3) -> Dictionary[StringName, Variant]:
	var p1_combined_normals: Array[FixedVector3] = []
	var p1_wall_ids: PackedInt64Array = []
	var p2_combined_normals: Array[FixedVector3] = []
	var p2_wall_ids: PackedInt64Array = []

	for entry: Dictionary[StringName, Variant] in self.stage_wall_detection_areas:

		var vals: Array[bool] = CollisionMath.IsInsidePolygon(p1_loc, p2_loc, entry[&"extents"])

		if vals[0]:
			# print("wall id: " + str(entry[&"wall_id"]) + " normal: X-" + str(entry[&"normal"].x) + " Z-" + str(entry[&"normal"].z))
			p1_combined_normals.append(entry[&"normal"])
			p1_wall_ids.append(entry[&"wall_id"])

		if vals[1]:
			p2_combined_normals.append(entry[&"normal"])
			p2_wall_ids.append(entry[&"wall_id"])

		if p1_combined_normals.size() >= 2 && p2_combined_normals.size() >= 2:
			break
	
	return {
		&"p1": combine_wall_data(p1_combined_normals, p1_wall_ids),
		&"p2": combine_wall_data(p2_combined_normals, p2_wall_ids),
	}

func combine_wall_data(combined_normals: Array[FixedVector3], wall_ids: PackedInt64Array) -> Dictionary[StringName, Variant]:
	if wall_ids.is_empty():
		return {
			&"wall_ids": wall_ids,
			&"normal": FixedVector3.new()
		}
	if wall_ids.size() == 1:
		# print("wall id: " + str(wall_ids[0]) + " normal: X-" + str(combined_normals[0].x) + " Z-" + str(combined_normals[0].z))
		return {
			&"wall_ids": wall_ids,
			&"normal": combined_normals[0]
		}

	var normal_accum: FixedVector3
	for i: int in range(1, combined_normals.size()):
		if i == 1:
			normal_accum = combined_normals[0]
		normal_accum = FixedVector3.Add(normal_accum, combined_normals[i]).Normalized()
	
	return {
		&"wall_ids": wall_ids,
		&"normal": normal_accum
	}

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

		var index: int = self.stage_bounds.find(entry)

		var label: Label3D = Label3D.new()

		label.text = str(index)
		label.position.y = 1
		label.scale *= 10
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		ray.add_child(label)

		ray.owner = EditorInterface.get_edited_scene_root()
		label.owner = EditorInterface.get_edited_scene_root()

func update_wall_detection_areas() -> void:
	var toaster: EditorToaster = EditorInterface.get_editor_toaster()

	self.stage_wall_detection_areas.clear()

	var wall_detection_areas: Array[Node] = get_tree().get_nodes_in_group(&"StageWallDetectionAreas")
	for area: CollisionPolygon3D in wall_detection_areas:
		# var area: CollisionPolygon3D = wall_detection_areas[idx]

		var wall_bound: Dictionary = self.stage_bounds[int(area.name)]
		var normal: Vector3 = Vector3()

		normal.x = FixedInt.ToFloat(wall_bound[&"end"][&"z"]) - FixedInt.ToFloat(wall_bound[&"start"][&"z"])
		normal.y = 0.0 
		normal.z = FixedInt.ToFloat(wall_bound[&"end"][&"x"]) - FixedInt.ToFloat(wall_bound[&"start"][&"x"])

		if wall_bound[&"x_positive"]:
			normal.x = absf(normal.x)
		else:
			normal.x = -absf(normal.x)
		if wall_bound[&"z_positive"]:
			normal.z = absf(normal.z)
		else:
			normal.z = -absf(normal.z)
		
		var entry: Dictionary[StringName, Variant] = {
			&"wall_id": int(area.name),
			&"extents": [
				FixedVector3.NewFromInt(FixedInt.FromFloat(area.polygon[0].x), 0, FixedInt.FromFloat(area.polygon[0].y)),
				FixedVector3.NewFromInt(FixedInt.FromFloat(area.polygon[1].x), 0, FixedInt.FromFloat(area.polygon[1].y)),
				FixedVector3.NewFromInt(FixedInt.FromFloat(area.polygon[2].x), 0, FixedInt.FromFloat(area.polygon[2].y)),
				FixedVector3.NewFromInt(FixedInt.FromFloat(area.polygon[3].x), 0, FixedInt.FromFloat(area.polygon[3].y))
			],
			&"normal": FixedVector3.NewFromVec3(normal).Normalized()
		}

		self.stage_wall_detection_areas.append(entry)
	
	toaster.push_toast("Wall Detection Areas saved!")
