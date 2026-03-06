@tool
extends GridContainer
class_name HitboxMenu

signal update_sphere(data: Dictionary)
signal update_data(data: Dictionary)

signal request_hitbox_removal()
signal request_dock_removal(node: HitboxMenu)

var data: Dictionary = {
	"sphere_radius": 0,
	"x_pos": 0,
	"y_pos": 0,
	"z_pos": 0,
	"frame_start": 0,
	"frame_end": 0,
	"attack_height": 0,
	"unblockable": false,
	"is_punch": false,
	"is_kick": false,
	"is_grab": false
}

var working_data: Dictionary

var hitbox_button_id: int
var hitbox_name: String

var is_hurtbox: bool = false

@onready var sphere: FECollisionShape

func _ready() -> void:
	self.working_data = self.data.duplicate(true)

	self.populate_data()

	self.get_sphere_in_editor()
	self.sphere.debug_shape_custom_color = Color.MAGENTA

func populate_data() -> void:
	%radiusVal.value = FixedInt.to_float(self.working_data["sphere_radius"])
	%XposVal.value = FixedInt.to_float(self.working_data["x_pos"])
	%YposVal.value = FixedInt.to_float(self.working_data["y_pos"])
	%ZposVal.value = FixedInt.to_float(self.working_data["z_pos"])
	%FrameStartVal.value = self.working_data["frame_start"]
	%FrameEndVal.value = self.working_data["frame_end"]
	%AttackHeightVal.selected = self.working_data["attack_height"]
	%UnblockableVal.button_pressed = self.working_data["unblockable"]
	%IsPunchVal.button_pressed = self.working_data["is_punch"]
	%IsKickVal.button_pressed = self.working_data["is_kick"]
	%IsGrabVal.button_pressed = self.working_data["is_grab"]	

func get_sphere_in_editor() -> void:
	var active_spheres: Array = EditorInterface.get_edited_scene_root() \
		.get_node("AddonSpheres") \
		.get_children()
	for node: FECollisionShape in active_spheres:
		if node.name == self.get_formatted_sphere_name():
			self.sphere = node
			return
				
	if self.sphere == null:
		var new_sphere: FECollisionShape = FECollisionShape.new()

		EditorInterface.get_edited_scene_root().get_node("AddonSpheres") \
			.add_child(new_sphere)

		new_sphere.owner = EditorInterface.get_edited_scene_root()

		new_sphere.fixed_sphere_radius = self.working_data["sphere_radius"]
		new_sphere.fixed_position = FixedVector3.new(
			self.working_data["x_pos"],
			self.working_data["y_pos"],
			self.working_data["z_pos"]
		)

		new_sphere.name = self.get_formatted_sphere_name()
		self.sphere = new_sphere

func get_formatted_sphere_name() -> String:
	return "%s_[%d]%s" % ["hit" if !self.is_hurtbox else "hurt", self.hitbox_button_id, self.hitbox_name]

func apply_hitbox_changes() -> void:
	self.data = self.working_data.duplicate(true)
	self.update_sphere.emit(self.data)
	self.update_data.emit(self.data)

func _on_update_sphere(data: Dictionary) -> void:
	if self.sphere == null:
		self.get_sphere_in_editor()
		if self.sphere == null:
			return
	self.sphere.fixed_sphere_radius = self.working_data["sphere_radius"]

	self.sphere.fixed_position = FixedVector3.new(
		self.working_data["x_pos"],
		self.working_data["y_pos"],
		self.working_data["z_pos"]
	)

func _exit_tree() -> void:
	self.sphere.debug_shape_custom_color = Color.YELLOW

func _on_radius_val_value_changed(value: float) -> void:
	self.working_data["sphere_radius"] = FixedInt.from_float(value)
	self.update_sphere.emit(self.working_data)

func _on_xpos_val_value_changed(value: float) -> void:
	self.working_data["x_pos"] = FixedInt.from_float(value)
	self.update_sphere.emit(self.working_data)

func _on_ypos_val_value_changed(value: float) -> void:
	self.working_data["y_pos"] = FixedInt.from_float(value)
	self.update_sphere.emit(self.working_data)

func _on_zpos_val_value_changed(value: float) -> void:
	self.working_data["z_pos"] = FixedInt.from_float(value)
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

func _on_confirm_delete_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%DeleteHitboxButton.disabled = false
	else:
		%DeleteHitboxButton.disable = true

func _on_delete_hitbox_button_button_up() -> void:
	self.sphere.queue_free()
	self.request_hitbox_removal.emit()
	self.request_dock_removal.emit(self)
