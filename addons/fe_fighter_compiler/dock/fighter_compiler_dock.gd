@tool
extends Control
class_name FighterCompilerDock

signal request_hitbox_menu(node: HitboxButton, idx: int, name: String)
signal request_bake_velocity_menu()

signal animation_frame_changed(frame: float)

signal reload_movelistitem_refs(refs: Array)

const move_list_item: Resource = preload('res://addons/fe_fighter_compiler/dock/MoveListItem.tscn')

var tick_time: float = (1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))

var anim_player: NetworkAnimationPlayer:
	get:
		return self.fighter.get_node("NetworkAnimationPlayer")

var fighter: Fighter

var selected_item: MoveListItem

# var process: bool = false

func _ready() -> void:
	# self.process = true

	var root: Node = EditorInterface.get_edited_scene_root()

	if root is not Fighter:
		return

	self.attach_to_fighter_scene()
	self.load_animation_data()
	self.load_movelist_data()

func load_animation_data() -> void:

	self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

	var animations: PackedStringArray = self.anim_player.get_animation_list()

	%AnimationSelector.clear()
	for i in animations.size():
		%AnimationSelector.add_item(animations[i])
		if animations[i] == self.anim_player.current_animation:
			%AnimationSelector.selected = i

	self.anim_player.seek(0.0)
	self.animation_frame_changed.emit(0.0)

# Populates move list from movelist data attached to fighter scene
func load_movelist_data() -> void:
	for n: Node in %MoveListView.get_child(0).get_children():
		n.queue_free()

	# self.fighter.movelist.move_list.sort()
	
	for key: int in self.fighter.movelist.move_list.size():
		var move: FighterAnimationData = self.fighter.movelist.move_list.get(str(key))
		self.add_movelist_item(move)
	
	for key: int in self.fighter.movelist.move_list.size():
		var move: FighterAnimationData = self.fighter.movelist.move_list.get(str(key))
		self.check_and_mark_movelist_ref(move)

	for key: int in self.fighter.movelist.move_list.size():
		var move: FighterAnimationData = self.fighter.movelist.move_list.get(str(key))
		self.refresh_movelist_refs(move)

func attach_to_fighter_scene() -> void:
	if EditorInterface.get_edited_scene_root() is FighterCompilerDock:
		return

	if EditorInterface.get_edited_scene_root() is not Fighter:
		%SelectFighterLabel.visible = true
		%MoveListControls.visible = false
		%MoveListView.visible = false
		return

	self.fighter = EditorInterface.get_edited_scene_root()

	%SelectFighterLabel.visible = false
	%MoveListControls.visible = true
	%MoveListView.visible = true

func add_movelist_item(data: FighterAnimationData = null, index: int = -1) -> void:	
	var item: MoveListItem = self.move_list_item.instantiate()

	item.character_animations = self.fighter.animation_library

	item.is_selected.connect(self._on_MoveListItem_is_selected)
	item.is_unselected.connect(self._on_MoveListItem_is_unselected)
	item.request_hitbox_menu.connect(self._on_MoveListItem_request_hitbox_menu)
	item.request_movelist_refs.connect(self._on_MoveListItem_request_movelist_refs)
	item.request_new_item.connect(self._on_MoveListItem_request_new_item)
	item.request_duplicate_item.connect(self._on_MoveListItem_request_duplicate_item)

	self.animation_frame_changed.connect(item._on_dock_animation_frame_changed)
	self.reload_movelistitem_refs.connect(item._on_FighterCompilerDock_reload_movelistitem_refs)

	%MoveListView.get_child(0).add_child(item)
	if index != -1:
		%MoveListView.get_child(0).move_child(item, index)

	if data == null:
		item.emit_signal("request_movelist_refs") # need to emit this to populate refs on new list item
		return # return if there is no data to populate

	item.source_data = data

	item.get_node("%MoveNameLabel").text = data.move_name
	item.get_node("%ButtonInputOption").selected = data.input_button
	item.get_node("%PushbackForce").value = data.pushback_force
	item.get_node("%NoInput").button_pressed = data.no_input if data.get("no_input") != null else false
	item.get_node("%SideContext").selected = data.side_context if data.get("side_context") != null else 0
	item.get_node("%RequiredState").text = data.required_state if data.get("required_state") != null else ""
	item.get_node("%HoldInput").button_pressed = data.hold_input if data.get("hold_input") != null else false
	item.get_node("%HoldInput").disabled = item.get_node("%NoInput").button_pressed
	item.get_node("%OnBlockToggle").button_pressed = data.has_block_recovery if data.get("has_block_recovery") != null else false
	item.get_node("%OnCounterOpponentToggle").button_pressed = data.has_counter_property if data.get("has_counter_property") != null else false
	item.get_node("%NonAttackToggle").button_pressed = data.non_attack if data.get("non_attack") != null else false

	#animation for move
	for i: int in item.get_node("%MoveAnimationOption").item_count:
		if data.animation_name == item.get_node("%MoveAnimationOption").get_item_text(i):
			item.get_node("%MoveAnimationOption").selected = i
			break

	#directional input sequence
	for i: int in data.input_di_map.size():
		var di_option: OptionButton = item.get_node("%DirectionalInputOption")
		if i != 0:
			di_option = di_option.duplicate()
			item.get_node("%InputSequence") \
				.get_child(item.get_node("%InputSequence").get_child_count() - 2) \
				.add_sibling(di_option)
		di_option.selected = data.input_di_map[i]

	# blocked attack animation (attacker)
	for i: int in item.get_node("%OnBlockOption").item_count:
		if str(data.recovery_block) == item.get_node("%OnBlockOption").get_item_text(i):
			item.get_node("%OnBlockOption").selected = i
			break

	# blocked attack animation (Opponent)
	for i: int in item.get_node("%OnBlockOpponentOption").item_count:
		if data.block_animation == item.get_node("%OnBlockOpponentOption").get_item_text(i):
			item.get_node("%OnBlockOpponentOption").selected = i
			break

	# hit animation (opponent)
	for i:int in item.get_node("%OnHitOpponentOption").item_count:
		if data.hit_animation == item.get_node("%OnHitOpponentOption").get_item_text(i):
			item.get_node("%OnHitOpponentOption").selected = i
			break

	# counter hit anim (opponent)
	for i: int in item.get_node("%OnCounterOpponentOption").item_count:
		if data.counter_animation == item.get_node("%OnCounterOpponentOption").get_item_text(i):
			item.get_node("%OnCounterOpponentOption").selected = i
			break

	# frame data here??? do i even need to do anything with that?

	#player states
	for key: String in data.player_states:
		item.add_player_state(data.player_states[key], key)

	#hitboxes
	if data.hitbox_data.has("shapes"):
		for i: Dictionary in data.hitbox_data["shapes"]:
			# need to transpose data lol
			i["sphere_radius"] = i["radius"]
			i["x_pos"] = i["position"].x
			i["y_pos"] = i["position"].y
			i["z_pos"] = i["position"].z
			i["frame_start"] = i["frame_range"]["start"]
			i["frame_end"] = i["frame_range"]["end"]
			item.add_hitbox(false, i)

	#hurtboxes
	if data.hurtbox_data.has("shapes"):
		for i: Dictionary in data.hurtbox_data["shapes"]:
			# need to transpose data lol
			i["sphere_radius"] = i["radius"]
			i["x_pos"] = i["position"].x
			i["y_pos"] = i["position"].y
			i["z_pos"] = i["position"].z
			i["frame_start"] = i["frame_range"]["start"]
			i["frame_end"] = i["frame_range"]["end"]
			item.add_hitbox(true, i)

func check_and_mark_movelist_ref(data: FighterAnimationData) -> void:
	var move: Variant = self.get_movelistitem_from_animationdata(data)
	if move is MoveListItem:
		move.get_node("%IsReference").button_pressed = data.is_reference

func get_movelistitem_from_animationdata(data: FighterAnimationData) -> Variant:
	var movelist: Array = %MoveListView.get_child(0).get_children()
	for move: MoveListItem in movelist:
		if move.move_name == data.move_name:
			return move
	return

func refresh_movelist_refs(data: FighterAnimationData) -> void:
	var move: Variant = self.get_movelistitem_from_animationdata(data)
	if move is MoveListItem:
		for i: int in move.get_node("%OnRecoveryRef").item_count:
			if data.recovery_ref == move.get_node("%OnRecoveryRef").get_item_text(i):
				move.get_node("%OnRecoveryRef").selected = i
				break

func empty_hitbox_visuals():
	var spheres: Array = EditorInterface.get_edited_scene_root().get_node("AddonSpheres").get_children()
	for i: Node in spheres:
		i.queue_free()

func get_movelist_refs() -> Array:
	var refs: Array = []
	for i: MoveListItem in %MoveListView.get_child(0).get_children():
		if !i.is_reference:
			continue
		refs.append(i)
	return refs

# =========================

func _on_MoveListItem_is_selected(move: MoveListItem) -> void:
	self.selected_item = move

	for item: MoveListItem in %MoveListView.get_child(0).get_children():
		if item == move:
			continue
		item.deselect()

	for i: int in %AnimationSelector.item_count:

		if move.move_animation_option.get_item_text(move.move_animation_option.selected) == \
			%AnimationSelector.get_item_text(i):
			%AnimationSelector.selected = i
			%AnimationSelector.emit_signal("item_selected", i)
			break

func _on_MoveListItem_is_unselected() -> void:
	pass # maybe ill use this later idk

func _on_MoveListItem_request_movelist_refs() -> void:
	self.reload_movelistitem_refs.emit(self.get_movelist_refs())

func _on_MoveListItem_request_hitbox_menu(hitbox: HitboxButton, idx: int, name: String) -> void:
	self.request_hitbox_menu.emit(hitbox, idx, name)

func _on_MoveListItem_request_new_item(index: int) -> void:
	self.add_movelist_item(null, index)

func _on_MoveListItem_request_duplicate_item(data: FighterAnimationData, index: int) -> void:
	self.add_movelist_item(data, index)
	var toaster: EditorToaster = EditorInterface.get_editor_toaster()
	toaster.push_toast("Movelist item duplicated. If data is incorrect, try compiling before duping.")

func _on_animation_selector_item_selected(index: int) -> void:
	self.anim_player.play(%AnimationSelector.get_item_text(index))
	self.anim_player.seek(0.0)
	self.animation_frame_changed.emit(0.0)

func _on_seek_forward_button_up() -> void:
	if self.anim_player.current_animation_position >= self.anim_player.current_animation_length:
		return

	var seek_position: float = clampf(self.anim_player.current_animation_position + self.tick_time, 0.0, 99999.0)
	var curr_anim: StringName = self.anim_player.current_animation

	self.animation_frame_changed.emit(seek_position * 60)

	await get_tree().create_timer(0.001).timeout

	self.anim_player.play(curr_anim)
	self.anim_player.seek(
		seek_position,
		true
	)

func _on_seek_back_button_up() -> void:
	if self.anim_player.current_animation_position <= 0:
		return
	
	var seek_position: float = clampf(self.anim_player.current_animation_position - self.tick_time, 0.0, 99999.0)
	var curr_anim: StringName = self.anim_player.current_animation

	self.animation_frame_changed.emit(seek_position * 60)

	await get_tree().create_timer(0.001).timeout

	self.anim_player.play(curr_anim)
	self.anim_player.seek(
		seek_position,
		true
	)


func _on_add_move_button_up() -> void:
	self.add_movelist_item()

func _on_remove_move_button_up() -> void:
	self.anim_player.seek(
		clampf(self.anim_player.current_animation_position + self.tick_time, 0.0, 99999.0)
	)

	self.animation_frame_changed.emit(self.anim_player.current_animation_position * 60)

	for item: MoveListItem in %MoveListView.get_child(0).get_children():
		if item.selected:
			item.deselect()
			item.queue_free()
			break

func _on_animation_frame_changed(frame: float) -> void:
	%FrameLabel.text = "Frame: " + str(roundf(frame))

func _on_compile_movelist_button_button_up() -> void:
	var toaster: EditorToaster = EditorInterface.get_editor_toaster()
	toaster.push_toast("Compiling Movelist...")

	var move_list: FighterMovelist = FighterMovelist.new()

	for item: MoveListItem in %MoveListView.get_child(0).get_children():
		var anim_data: FighterAnimationData = FighterAnimationData.new()
		var inputs: Array = []

		anim_data.move_name = item.move_name
		anim_data.add_inputs_arr(item.get_input_map())
		anim_data.animation_name = item.get_animation_name()
		anim_data.hit_animation = item.get_node("%OnHitOpponentOption").text
		anim_data.block_animation = item.get_node("%OnBlockOpponentOption").text
		anim_data.has_counter_property = item.get_node("%OnCounterOpponentToggle").button_pressed
		anim_data.counter_animation = item.get_node("%OnCounterOpponentOption").text
		anim_data.pushback_force = item.get_node("%PushbackForce").value
		anim_data.is_reference = item.is_reference
		anim_data.has_block_recovery = item.get_node("%OnBlockToggle").button_pressed
		anim_data.recovery_block = item.get_node("%OnBlockOption").text
		anim_data.recovery_ref = item.get_node("%OnRecoveryRef").get_item_text(item.get_node("%OnRecoveryRef").selected)
		anim_data.no_input = item.get_node("%NoInput").button_pressed
		anim_data.side_context = item.get_node("%SideContext").selected
		anim_data.required_state = item.get_node("%RequiredState").text
		anim_data.hold_input = item.get_node("%HoldInput").button_pressed
		anim_data.non_attack = item.get_node("%NonAttackToggle").button_pressed

		# add frame data here???

		anim_data.hitbox_data = item.get_hitbox_data()
		anim_data.hurtbox_data = item.get_hitbox_data(true)

		anim_data.player_states = item.get_state_data()

		move_list.add_to_list(anim_data)

	# done?
	# -> send + apply data to fighter scene
	move_list.take_over_path("res://character/movelists/%s_movelist.tres" % self.fighter.fighter_name)
	self.fighter.movelist = move_list

	toaster.push_toast("Movelist compiled! Saving to disk...")

	ResourceSaver.save(self.fighter.movelist, "res://character/movelists/%s_movelist.tres" % self.fighter.fighter_name)

	toaster.push_toast("Saved Movelist to disk.")

func _on_bake_velocity_data_button_button_up() -> void:
	self.request_bake_velocity_menu.emit()

func _on_reattach_button_button_up() -> void:
	self.attach_to_fighter_scene()
	self.load_animation_data()
	self.load_movelist_data()

func _on_check_box_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		for item: MoveListItem in %MoveListView.get_child(0).get_children():
			if !item.visible:
				item.visible = true;
		return
	var count: int = 0
	for item: MoveListItem in %MoveListView.get_child(0).get_children():
		if item.get_node("%NonAttackToggle").button_pressed:
			item.visible = false
			%MoveListView.get_child(0).move_child(item, count)
			count += 1

func _on_empty_list_button_button_up() -> void:
	for n: Node in %MoveListView.get_child(0).get_children():
		n.queue_free()
