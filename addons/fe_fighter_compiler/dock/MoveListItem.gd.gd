@tool
extends PanelContainer
class_name MoveListItem

signal is_selected(source)
signal is_unselected

signal animation_frame_changed(frame: float)

signal request_hitbox_menu(hitbox: HitboxButton)

const animation_state = preload("res://addons/fe_fighter_compiler/dock/animation_state.tscn")
const hitbox_button = preload("res://addons/fe_fighter_compiler/dock/HitboxButton.tscn")

@export var default_animations: AnimationLibrary
@export var hit_animations: AnimationLibrary
@export var block_animations: AnimationLibrary

var character_animations: AnimationLibrary

var move_name: String

var anim_names: Array[StringName]:
	get:
		var arr = self.default_animations.get_animation_list() + \
			self.hit_animations.get_animation_list() + \
			self.block_animations.get_animation_list()
		if self.character_animations != null:
			arr += self.character_animations.get_animation_list()
		return arr		

func _ready() -> void:
	self.move_name = %MoveNameLabel.text

	for name: StringName in self.anim_names:
		%MoveAnimationOption.add_item(name)
	# for name: StringName in self.block_animations: # used for stagger effects on blocked attacks
	# 	%OnBlockOption.add_item(name)
	for name: StringName in self.block_animations:
		%OnBlockOpponentOption.add_item(name)
	for name: StringName in self.hit_animations:
		%OnHitOpponentOption.add_item(name)
		%OnCounterOpponentOption.add_item(name)
	%MoveData.folded = true

# ======================

func deselect():
	%IsSelected.button_pressed = false

func get_input_map() -> Array:
	var val := []
	for node in %InputSequence.get_children():
		if node is OptionButton:
			val.append(node.selected)
	val.append(%ButtonInputOption.selected)
	return val

func get_animation_name():
	return %MoveAnimationOption.text

func get_hitbox_data(is_hurtbox := false) -> Dictionary:
	var val := {}

	var boxes: Array

	var frame_start := -1
	var frame_end := -1

	if is_hurtbox:
		boxes = %HurtboxGrid.get_children()
	else:
		boxes = %HitboxGrid.get_children()
	
	if !boxes.is_empty():
		val["shapes"] = []
		for box: HitboxButton in boxes:

			if box.frame_start < frame_start || frame_start == -1:
				frame_start = box.frame_start
			if box.frame_end > frame_end:
				frame_end = box.frame_end

			var data := {}

			data["radius"] = box.sphere_radius
			data["position"] = FixedVector3.new(
				box.x_pos,
				box.y_pos,
				box.z_pos
			)
			data["frame_range"] = {
				"start": box.frame_start,
				"end": box.frame_end
			}
			data["attack_height"] = box.attack_height

			
	val["frame_range"] = {
		"start": frame_start,
		"end": frame_end
	}
	val["hit_anim"] = %OnHitOpponentOption.text
	val["block_anim"] = %OnBlockOpponentOption.text
	val["pushback_force"] = %PushbackForce.value
		
	return val

func get_state_data() -> Dictionary:
	var val := {}

	for state: AnimationState in %DefaultStatesContainer:
		val.merge(state.get_state_data())

	return val


# ======================

func _on_is_selected_toggled(toggled_on: bool) -> void:
	if toggled_on:
		self.is_selected.emit(self)

func _on_add_directional_input_button_up() -> void:
	var opt = %DirectionalInputOption.duplicate()
	%InputSequence.get_child(%InputSequence.get_child_count() - 2).add_sibling(opt)

func _on_remove_directional_input_button_up() -> void:
	if %InputSequence.get_child_count() <= 2:
		return
	%InputSequence.get_child(%InputSequence.get_child_count() - 2).free()

func _on_on_block_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%OnBlockOption.disabled = false
		return
	%OnBlockOption.disabled = true

func _on_on_counter_opponent_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%OnCounterOpponentOption.disabled = false
		return
	%OnCounterOpponentOption.disabled = true

func _on_button_button_up() -> void:
	var anim_state = self.animation_state.instantiate()
	%DefaultStatesContainer.add_child(anim_state)

func _on_add_hitbox_button_up() -> void:
	var button = self.hitbox_button.instantiate()
	%HitboxGrid.add_child(button)
	button.clicked.connect(_on_hitbox_button_clicked)

func _on_add_hurtbox_button_up() -> void:
	var button: HitboxButton = self.hitbox_button.instantiate()
	button.is_hurtbox = true
	%HurtboxGrid.add_child(button)
	button.clicked.connect(_on_hitbox_button_clicked)

func _on_hitbox_button_clicked(hitbox: HitboxButton) -> void:
	self.request_hitbox_menu.emit(hitbox)

func _on_dock_animation_frame_changed(frame: float) -> void:
	# self.animation_frame_changed.emit(frame)
	if !%IsSelected.toggled:
		return

	var spheres = EditorInterface.get_edited_scene_root().get_node("AddonSpheres").get_children()
	for sphere in spheres:
		sphere.queue_free()

	var hitboxes = %HitboxGrid.get_children()
	for hitbox: HitboxButton in hitboxes:
		if !(hitbox.frame_start <= frame && frame < hitbox.frame_end):
			continue

		var new_sphere := FECollisionShape.new()
		new_sphere.fixed_sphere_radius = hitbox.sphere_radius
		new_sphere.fixed_position = FixedVector3.new(
			hitbox.x_pos,
			hitbox.y_pos,
			hitbox.z_pos
		)
		new_sphere.debug_shape_custom_color = Color.YELLOW

	var hurtboxes = %HurtboxGrid.get_children()
	for hurtbox: HitboxButton in hurtboxes:
		var new_sphere := FECollisionShape.new()
		new_sphere.fixed_sphere_radius = hurtbox.sphere_radius
		new_sphere.fixed_position = FixedVector3.new(
			hurtbox.x_pos,
			hurtbox.y_pos,
			hurtbox.z_pos
		)
		new_sphere.debug_shape_custom_color = Color.WHITE