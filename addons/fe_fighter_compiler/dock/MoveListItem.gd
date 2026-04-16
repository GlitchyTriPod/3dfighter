@tool
extends PanelContainer
class_name MoveListItem

signal is_selected(source)
signal is_unselected

signal animation_changed(anim_name: String)
signal animation_frame_changed(frame: float)

signal request_hitbox_menu(hitbox: HitboxButton, idx: int, name: String)

signal request_movelist_refs

const animation_state = preload("res://addons/fe_fighter_compiler/dock/animation_state.tscn")
const hitbox_button = preload("res://addons/fe_fighter_compiler/dock/HitboxButton.tscn")

@export var default_animations: AnimationLibrary
@export var hit_animations: AnimationLibrary
@export var block_animations: AnimationLibrary

@onready var move_animation_option : OptionButton = %MoveAnimationOption

var character_animations: AnimationLibrary = null

var move_name: String:
	get:
		return %MoveNameLabel.text

var selected: bool = false
var is_reference: bool = false
var no_input: bool = false

var anim_names: Array[String]:
	get:
		var arr: Array[String] = []

		for name: StringName in self.default_animations.get_animation_list():
			arr.append("%s/%s" % [self.default_animations.resource_name, name])
		for name: StringName in self.block_animations.get_animation_list():
			arr.append("%s/%s" % [self.block_animations.resource_name, name])
		for name: StringName in self.hit_animations.get_animation_list():
			arr.append("%s/%s" % [self.hit_animations.resource_name, name])

		if self.character_animations != null:
			for name: StringName in self.character_animations.get_animation_list():
				arr.append("%s/%s" % [self.character_animations.resource_name, name])

		# arr = self.default_animations.get_animation_list() + \
		# 	self.hit_animations.get_animation_list() + \
		# 	self.block_animations.get_animation_list()
		# # if self.character_animations != null:
		# # 	arr += self.character_animations.get_animation_list()

		return arr		

func _ready() -> void:
	if EditorInterface.get_edited_scene_root() == self:
		return

	self.move_name = %MoveNameLabel.text

	%MoveAnimationOption.clear()
	%OnBlockOption.clear()
	%OnBlockOpponentOption.clear()
	%OnHitOpponentOption.clear()
	%OnCounterOpponentOption.clear()

	for name: StringName in self.anim_names:
		%MoveAnimationOption.add_item(name)
	for name: StringName in self.anim_names: # used for stagger effects on blocked attacks
		%OnBlockOption.add_item(name)
	for name: StringName in self.block_animations.get_animation_list():
		%OnBlockOpponentOption.add_item("%s/%s" % [self.block_animations.resource_name, name])
	for name: StringName in self.hit_animations.get_animation_list():
		%OnHitOpponentOption.add_item("%s/%s" % [self.hit_animations.resource_name, name])
		%OnCounterOpponentOption.add_item("%s/%s" % [self.hit_animations.resource_name, name])
	%MoveData.folded = true

	# self.theme

# ======================

func deselect():
	%IsSelected.button_pressed = false

func get_input_map() -> Array:
	var val: Array = []
	for node: Node in %InputSequence.get_children():
		if node is OptionButton:
			val.append(node.selected)
	val.append(%ButtonInputOption.get_item_text(%ButtonInputOption.selected))
	return val

func get_animation_name():
	return %MoveAnimationOption.text

func get_hitbox_data(is_hurtbox := false) -> Dictionary:
	var val: Dictionary = {}

	var boxes: Array

	var frame_start: int = -1
	var frame_end: int = -1

	if is_hurtbox:
		boxes = %HurtboxGrid.get_children()
	else:
		boxes = %HitboxGrid.get_children()

		val["frame_range"] = {
			"start": frame_start,
			"end": frame_end
		}
		# val["hit_anim"] = %OnHitOpponentOption.text
		# val["block_anim"] = %OnBlockOpponentOption.text
		# val["pushback_force"] = %PushbackForce.value
	
	if !boxes.is_empty():
		val["shapes"] = []
		for box: HitboxButton in boxes:

			if box.frame_start < frame_start || frame_start == -1:
				frame_start = box.frame_start
			if box.frame_end > frame_end:
				frame_end = box.frame_end

			var data: Dictionary = {}

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
			data["unblockable"] = box.unblockable
			data["is_grab"] = box.is_grab
			data["is_punch"] = box.is_punch
			data["is_kick"] = box.is_kick

			val["shapes"].append(data)

	return val

func get_state_data() -> Dictionary:
	var val: Dictionary = {}

	for state: AnimationState in %DefaultStatesContainer.get_children():
		val.merge(state.get_state_data())

	return val

func add_player_state(data: Dictionary = {}, state_name: String = "") -> void:
	var anim_state: AnimationState = self.animation_state.instantiate()
	%DefaultStatesContainer.add_child(anim_state)
	if data.is_empty():
		return

	# await anim_state.ready
	anim_state.get_node("%StateName").text = state_name
	anim_state.get_node("%FrameStart").value = data["start"]
	anim_state.get_node("%FrameEnd").value = data["end"]

func add_hitbox(is_hurtbox: bool = false, data: Dictionary = {}):
	var button: HitboxButton = self.hitbox_button.instantiate()
	button.is_hurtbox = is_hurtbox
	if is_hurtbox:
		%HurtboxGrid.add_child(button)
	else:
		%HitboxGrid.add_child(button)
	button.clicked.connect(self._on_hitbox_button_clicked)

	if data.is_empty():
		return

	# await button.ready
	button.update_data(data)

# func load_refs() -> void:
# 	pass

# ======================

func _on_is_selected_toggled(toggled_on: bool) -> void:
	self.selected = toggled_on
	if toggled_on:
		self.is_selected.emit(self)
		var stylebox: StyleBox = self.get_theme_stylebox("panel").duplicate()
		stylebox.border_color = Color("#3d5ff9")
		self.add_theme_stylebox_override("panel", stylebox)
	else:
		self.is_unselected.emit()
		var stylebox: StyleBox = self.get_theme_stylebox("panel").duplicate()
		stylebox.border_color = Color("#3b2020")
		self.add_theme_stylebox_override("panel", stylebox)

func _on_add_directional_input_button_up() -> void:
	var opt: OptionButton = %DirectionalInputOption.duplicate()
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

# add player state
func _on_button_button_up() -> void:
	self.add_player_state()

func _on_add_hitbox_button_up() -> void:
	self.add_hitbox()

func _on_add_hurtbox_button_up() -> void:
	self.add_hitbox(true)

func _on_hitbox_button_clicked(hitbox: HitboxButton) -> void:
	var idx: int = %HitboxGrid.get_children().find(hitbox)
	self.request_hitbox_menu.emit(hitbox, idx, self.move_name)

func _on_dock_animation_frame_changed(frame: float) -> void:
	if !%IsSelected.button_pressed:
		return

	var spheres: Array = EditorInterface.get_edited_scene_root().get_node("AddonSpheres").get_children()
	for sphere: Node in spheres:
		sphere.queue_free()

	var hitboxes: Array = %HitboxGrid.get_children()
	for i: int in hitboxes.size():
		var hitbox: HitboxButton = hitboxes[i]
		if !(hitbox.frame_start <= frame && frame < hitbox.frame_end):
			continue

		var new_sphere: FECollisionShape = FECollisionShape.new()

		EditorInterface.get_edited_scene_root().get_node("AddonSpheres") \
			.add_child(new_sphere)		
		new_sphere.owner = EditorInterface.get_edited_scene_root()

		new_sphere.fixed_sphere_radius = hitbox.sphere_radius
		new_sphere.fixed_position = FixedVector3.new(
			hitbox.x_pos,
			hitbox.y_pos,
			hitbox.z_pos
		)
		new_sphere.debug_shape_custom_color = Color.YELLOW

		new_sphere.name = "hit_[%d]%s" % [i, self.move_name]

	var hurtboxes: Array = %HurtboxGrid.get_children()
	for i: int in hurtboxes.size():
		var hurtbox: HitboxButton = hurtboxes[i]
		var new_sphere: FECollisionShape = FECollisionShape.new()
		
		EditorInterface.get_edited_scene_root().get_node("AddonSpheres") \
			.add_child(new_sphere)		
		new_sphere.owner = EditorInterface.get_edited_scene_root()

		new_sphere.fixed_sphere_radius = hurtbox.sphere_radius
		new_sphere.fixed_position = FixedVector3.new(
			hurtbox.x_pos,
			hurtbox.y_pos,
			hurtbox.z_pos
		)
		new_sphere.debug_shape_custom_color = Color.WHITE

		new_sphere.name = "hurt_[%d]%s" % [i, self.move_name]

func _on_move_animation_option_item_selected(index: int) -> void:
	self.animation_changed.emit(%MoveAnimationOption.get_item_text(index))

func _on_is_reference_toggled(toggled_on: bool) -> void:
	if toggled_on:
		self.is_reference = true
	else:
		self.is_reference = false
	self.request_movelist_refs.emit()

func _on_FighterCompilerDock_reload_movelistitem_refs(refs: Array) -> void:
	var selected_ref: String = %OnRecoveryRef.get_item_text(%OnRecoveryRef.selected)
	var index: int = -1
	%OnRecoveryRef.clear()
	for i: int in refs.size():
		%OnRecoveryRef.add_item("Ref/%s" % [refs[i]["move_name"]])
		if selected_ref == "Ref/%s" % [refs[i]["move_name"]]:
			index = i

	%OnRecoveryRef.selected = index

func _on_no_input_toggled(toggled_on: bool) -> void:
	self.no_input = toggled_on
	%HoldInput.disabled = toggled_on
	%DirectionalInputOption.disabled = toggled_on
	%AddDirectionalInput.disabled = toggled_on
	%RemoveDirectionalInput.disabled = toggled_on
	
func _on_non_attack_toggled(toggled_on: bool) -> void:
	%OnBlockOpponentOption.disabled = toggled_on
	%OnHitOpponentOption.disabled = toggled_on
	%OnBlockToggle.disabled = toggled_on
	%OnCounterOpponentToggle.disabled = toggled_on
	%AddHitbox.disabled = toggled_on
	%AddHurtbox.disabled = toggled_on
