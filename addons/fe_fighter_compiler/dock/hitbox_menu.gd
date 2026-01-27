@tool
extends GridContainer
class_name HitboxMenu

signal update_sphere(data: Dictionary)
signal update_data(data: Dictionary)
signal request_dock_removal(node)

var data: Dictionary

var working_data: Dictionary

@onready var sphere: FECollisionShape

func _ready() -> void:
	self.get_sphere_in_editor()
	self.sphere.debug_shape_custom_color = Color.MAGENTA
	self.working_data = self.data.duplicate(true)

func get_sphere_in_editor():
	var active_spheres: Array = EditorInterface.get_edited_scene_root() \
		.get_node("AddonSpheres") \
		.get_children()
	for node: FECollisionShape in active_spheres:
		if node.fixed_sphere_radius == self.data["sphere_radius"] && \
			node.fixed_position.x == self.data["x_pos"] && \
			node.fixed_position.y == self.data["y_pos"] && \
			node.fixed_position.z == self.data["z_pos"]:
				self.sphere = node
				return
				
	# if self.sphere == null:
	# 	var new_sphere = FECollisionShape.new()
	# 	new_sphere.fixed_sphere_radius = data["sphere_radius"]
	# 	new_sphere.fixed_position = FixedVector3.new(
	# 		data["x_pos"],
	# 		data["y_pos"],
	# 		data["z_pos"]
	# 	)

	# 	EditorInterface.get_edited_scene_root().get_node("AddonSpheres") \
	# 		.add_child(new_sphere)

	# 	self.sphere = new_sphere

func apply_hitbox_changes() -> void:
	self.data: Dictionary = self.working_data.duplicate(true)
	self.update_sphere.emit(self.data)
	self.update_data.emit(self.data)

func _on_update_sphere(data: Dictionary) -> void:
	if self.sphere == null:
		self.get_sphere_in_editor()
		if self.sphere == null:
			return
	self.sphere.fixed_sphere_radius = data["sphere_radius"]
	self.sphere.fixed_position.x = data["x_pos"]
	self.sphere.fixed_position.y = data["y_pos"]
	self.sphere.fixed_position.z = data["z_pos"]

func _exit_tree() -> void:
	self.sphere.debug_shape_custom_color = Color.YELLOW

func _on_radius_val_value_changed(value: float) -> void:
	self.working_data["sphere_radius"] = FixedInt.from_int(int(value))
	self.update_sphere.emit(self.working_data)

func _on_xpos_val_value_changed(value: float) -> void:
	self.working_data["x_pos"] = FixedInt.from_int(int(value))
	self.update_sphere.emit(self.working_data)

func _on_ypos_val_value_changed(value: float) -> void:
	self.working_data["y_pos"] = FixedInt.from_int(int(value))
	self.update_sphere.emit(self.working_data)

func _on_zpos_val_value_changed(value: float) -> void:
	self.working_data["z_pos"] = FixedInt.from_int(int(value))
	self.update_sphere.emit(self.working_data)

func _on_frame_start_val_value_changed(value: float) -> void:
	self.working_data["frame_start"] = int(value)

func _on_frame_end_val_value_changed(value: float) -> void:
	self.working_data["frame_end"] = int(value)

func _on_attack_height_val_item_selected(index: int) -> void:
	self.working_data["attack_height"] = index

func _on_unblockable_val_toggled(toggled_on: bool) -> void:
	self.working_data["unblockable"] = toggled_on

func _on_is_punch_val_toggled(toggled_on: bool) -> void:
	self.working_data["is_punch"] = toggled_on

func _on_is_kick_val_toggled(toggled_on: bool) -> void:
	self.working_data["is_kick"] = toggled_on

func _on_is_grab_val_toggled(toggled_on: bool) -> void:
	self.working_data["is_grab"] = toggled_on

func _on_confirm_button_up() -> void:
	self.apply_hitbox_changes()
	var toaster: EditorToaster = EditorInterface.get_editor_toaster()
	toaster.push_toast("Hitbox values saved!")

func _on_cancel_button_up() -> void:
	self.update_sphere.emit(self.data)
	self.request_dock_removal.emit(self)
