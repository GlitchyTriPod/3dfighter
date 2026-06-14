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

func _ready() -> void:
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

	var move_list_sorted: Array[FighterAnimationData] = self.get_move_list_sorted()
	
	for key: FighterAnimationData in move_list_sorted: #
		self.add_movelist_item(key)
	
	for key: FighterAnimationData in move_list_sorted: 
		self.check_and_mark_movelist_ref(key)

	for key: FighterAnimationData in move_list_sorted: 
		self.refresh_movelist_refs(key)
	
	self.update_tree(move_list_sorted)

func get_move_list_sorted() -> Array[FighterAnimationData]:
	var move_list_sorted: Array[FighterAnimationData] = self.fighter.movelist.move_list.values()
	move_list_sorted.sort_custom(
		func(a: FighterAnimationData, b: FighterAnimationData) -> bool:
			if a.move_type < b.move_type:
				return true
			elif a.move_type > b.move_type:
				return false
			return a.move_name > b.move_name
	)
	return move_list_sorted

func attach_to_fighter_scene() -> void:
	if EditorInterface.get_edited_scene_root() is FighterCompilerDock:
		return

	if EditorInterface.get_edited_scene_root() is not Fighter:
		%SelectFighterLabel.visible = true
		%MoveListControls.visible = false
		%MoveListContainer.visible = false
		return

	self.fighter = EditorInterface.get_edited_scene_root()

	%SelectFighterLabel.visible = false
	%MoveListControls.visible = true
	%MoveListContainer.visible = true

func add_movelist_item(data: FighterAnimationData = null, index: int = -1, parent_item: MoveListItem = null) -> void:
	if data.get('is_extension_only') != null && data.is_extension_only && parent_item == null:
		return

	var item: MoveListItem = self.move_list_item.instantiate()

	item.character_animations = self.fighter.animation_library

	self.connect_MoveListItem_signals(item)

	if parent_item != null:
		item.parent_item = parent_item
		
		parent_item.get_node("%ExtensionMovelist").add_child(item)

		item.get_node("%IsReference").disabled = true
		item.get_node('%NewUpButton').disabled = true
		item.get_node('%NewDownButton').disabled = true
		item.get_node('%DupeUpButton').disabled = true
		item.get_node('%DupeDownButton').disabled = true

	else:
		%MoveListView.get_child(0).add_child(item)
		if index != -1:
			%MoveListView.get_child(0).move_child(item, index)

	if data == null:
		item.emit_signal("request_movelist_refs") # need to emit this to populate refs on new list item
		return # return if there is no data to populate

	item.source_data = data

	item.get_node("%MoveNameLabel").text = data.move_name
	item.get_node("%MoveType").selected = data.move_type if data.get("move_type") != null else 0
	item.get_node("%MoveType").emit_signal("item_selected", item.get_node("%MoveType").selected)

	#animation for move
	for i: int in item.get_node("%MoveAnimationOption").item_count:
		if data.animation_name == item.get_node("%MoveAnimationOption").get_item_text(i):
			item.get_node("%MoveAnimationOption").selected = i
			item.set_animation_length_label(
				self.anim_player.get_animation(data.animation_name).length
			)
			break

	item.get_node("%LookAtEnemy").button_pressed = data.look_at_enemy if data.get("look_at_enemy") != null else false

	#directional input sequence
	for i: int in data.input_di_map.size():
		var di_option: OptionButton = item.get_node("%DirectionalInputOption")
		if i != 0:
			di_option = di_option.duplicate()
			item.get_node("%InputSequence") \
				.get_child(item.get_node("%InputSequence").get_child_count() - 2) \
				.add_sibling(di_option)
		di_option.selected = data.input_di_map[i]

	item.get_node("%ButtonInputOption").selected = data.input_button

	item.get_node("%NoInput").button_pressed = data.no_input if data.get("no_input") != null else false
	item.get_node("%HoldInput").button_pressed = data.hold_input if data.get("hold_input") != null else false
	item.get_node("%HoldInput").disabled = item.get_node("%NoInput").button_pressed
	item.get_node("%NonAttackToggle").button_pressed = data.non_attack if data.get("non_attack") != null else false
	item.get_node("%NonBufferable").button_pressed = data.non_bufferable if data.get("non_bufferable") != null else false
	item.get_node("%SideContext").selected = data.side_context if data.get("side_context") != null else 0

	item.get_node("%TargetFaceAttackerHit").button_pressed = data.face_attacker_on_hit if data.get("face_attacker_on_hit") != null else false

	item.get_node("%RequiredState").text = ', '.join(data.required_state)	
	item.get_node("%ProhibitState").text = ', '.join(data.prohibit_state)

	item.get_node("%OnBlockToggle").button_pressed = data.has_block_recovery if data.get("has_block_recovery") != null else false
	item.get_node("%OnCrouchBlockOpponentToggle").button_pressed = data.has_crouch_block_property if data.get("has_crouch_block_property") != null else false
	item.get_node("%OnHitToggle").button_pressed = data.has_hit_recovery if data.get("has_hit_recovery") != null else false
	item.get_node("%OnCounterToggle").button_pressed = data.has_ch_recovery if data.get("has_ch_recovery") != null else false
	item.get_node("%OnCounterOpponentToggle").button_pressed = data.has_counter_property if data.get("has_counter_property") != null else false

	# blocked attack animation (attacker)
	for i: int in item.get_node("%OnBlockOption").item_count:
		if data.recovery_block == item.get_node("%OnBlockOption").get_item_text(i):
			item.get_node("%OnBlockOption").selected = i
			break

	# hit landed animation (attacker)
	for i: int in item.get_node("%OnHitOption").item_count:
		if data.recovery_hit == item.get_node("%OnHitOption").get_item_text(i):
			item.get_node("%OnHitOption").selected = i
			break
	
	# hit landed counter (attacker)
	for i: int in item.get_node("%OnCounterOption").item_count:
		if data.recovery_ch == item.get_node("%OnCounterOption").get_item_text(i):
			item.get_node("%OnCounterOption").selected = i
			break

	# blocked attack animation (Opponent)
	for i: int in item.get_node("%OnBlockOpponentOption").item_count:
		if data.block_animation == item.get_node("%OnBlockOpponentOption").get_item_text(i):
			item.get_node("%OnBlockOpponentOption").selected = i
			break

	# crouch blocked attack animation (Opponent)
	for i: int in item.get_node("%OnCrouchBlockOpponentOption").item_count:
		if data.crouch_block_animation == item.get_node("%OnCrouchBlockOpponentOption").get_item_text(i):
			item.get_node("%OnCrouchBlockOpponentOption").selected = i
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

	# back hit anim (opponent)
	for i: int in item.get_node("%OnBackHitOpponentOption").item_count:
		if data.back_hit_animation == item.get_node("%OnBackHitOpponentOption").get_item_text(i):
			item.get_node("%OnBackHitOpponentOption").selected = i
			break

	# air hit (opponent)
	for i: int in item.get_node("%OnAirHitOption").item_count:
		if data.air_hit_animation == item.get_node("%OnAirHitOption").get_item_text(i):
			item.get_node("%OnAirHitOption").selected = i
			break

	# ground hit (opponent)
	for i: int in item.get_node("%OnGroundHitOption").item_count:
		if data.ground_hit_animation == item.get_node("%OnGroundHitOption").get_item_text(i):
			item.get_node("%OnGroundHitOption").selected = i
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

	item.get_node("%PushbackForce").value = FixedInt.ToFloat(data.pushback_force)
	item.get_node("%PushbackDirection").value = FixedInt.ToFloat(FixedInt.Rads2Deg(data.pushback_direction if data.get("pushback_direction") != null else 0))
	item.get_node("%LaunchForce").value = FixedInt.ToFloat(data.launch_force if data.get("launch_force") != null else 0)
	item.get_node("%LaunchDirection").value = FixedInt.ToFloat(FixedInt.Rads2Deg(data.launch_direction if data.get("launch_direction") != null else 0))

	item.get_node('%PushbackForceModOnHit').value = FixedInt.ToFloat(data.pushback_mod_on_hit if data.get("pushback_mod_on_hit") != null else 0)
	item.get_node('%PushbackForceModOnCounter').value = FixedInt.ToFloat(data.pushback_mod_on_counter if data.get("pushback_mod_on_counter") != null else 0)
	item.get_node('%PushbackForceModOnGroundHit').value = FixedInt.ToFloat(data.pushback_mod_on_ground_hit if data.get("pushback_mod_on_ground_hit") != null else 0)
	item.get_node('%PushbackForceModOnBlock').value = FixedInt.ToFloat(data.pushback_mod_on_block if data.get("pushback_mod_on_block") != null else 0)

	item.get_node("%ApplyPushbackAngleOnHit").button_pressed = data.pushback_angle_on_hit if data.get("pushback_angle_on_hit") != null else true
	item.get_node("%ApplyPushbackAngleOnCounter").button_pressed = data.pushback_angle_on_counter if data.get("pushback_angle_on_counter") != null else true
	item.get_node("%ApplyPushbackAngleOnGroundHit").button_pressed = data.pushback_angle_on_ground_hit if data.get("pushback_angle_on_ground_hit") != null else true
	item.get_node("%ApplyPushbackAngleOnBlock").button_pressed = data.pushback_angle_on_block if data.get("pushback_angle_on_block") != null else true

	item.get_node("%ExtensionBufferStart").value = data.extension_buffer_start if data.get("extension_buffer_start") != null else -1
	item.get_node("%ExtensionExecuteStart").value = data.extension_execute_start if data.get("extension_execute_start") != null else -1
	item.get_node("%ExtensionExecuteEnd").value = data.extension_execute_end if data.get("extension_execute_end") != null else -1

	for extension: FighterAnimationData in data.extensions:
		self.add_movelist_item(extension, -1, item)

func connect_MoveListItem_signals(item: MoveListItem) -> void:
	item.is_selected.connect(self._on_MoveListItem_is_selected)
	item.is_unselected.connect(self._on_MoveListItem_is_unselected)
	item.request_hitbox_menu.connect(self._on_MoveListItem_request_hitbox_menu)
	item.request_movelist_refs.connect(self._on_MoveListItem_request_movelist_refs)
	item.request_new_item.connect(self._on_MoveListItem_request_new_item)
	item.request_duplicate_item.connect(self._on_MoveListItem_request_duplicate_item)
	item.request_connect_MoveListItem_signals.connect(self.connect_MoveListItem_signals)
	item.request_animation_length.connect(self._on_MoveListItem_request_animation_length)
	item.request_update_tree.connect(self.update_tree)

	self.animation_frame_changed.connect(item._on_dock_animation_frame_changed)
	self.reload_movelistitem_refs.connect(item._on_FighterCompilerDock_reload_movelistitem_refs)

func check_and_mark_movelist_ref(data: FighterAnimationData) -> void:
	var move: Variant = self.get_movelistitem_from_animationdata(data)
	if move is MoveListItem:
		move.get_node("%IsReference").button_pressed = data.is_reference

func get_movelistitem_from_animationdata(data: FighterAnimationData) -> Variant:
	var movelist: Array = get_tree().get_nodes_in_group("MoveListItems") #%MoveListView.get_child(0).get_children()
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
	for extension: FighterAnimationData in data.extensions:
		self.refresh_movelist_refs(extension)

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

func update_tree(move_list_sorted: Array[FighterAnimationData] = []) -> void:
	if move_list_sorted.is_empty():
		move_list_sorted = self.get_move_list_sorted()

	%MoveListTree.clear()
	var root: TreeItem = %MoveListTree.create_item()

	var root_movement: TreeItem = root.create_child()
	var root_attack: TreeItem = root.create_child()
	var root_ground_option: TreeItem = root.create_child()
	var root_hit_stun: TreeItem = root.create_child()
	var root_block_stun: TreeItem = root.create_child()

	root_movement.set_custom_bg_color(0, Color('#515f66'))
	root_movement.set_text(0, 'Movement')
	root_attack.set_custom_bg_color(0, Color("#665154"))
	root_attack.set_text(0, 'Attacks')
	root_ground_option.set_custom_bg_color(0, Color("#666551"))
	root_ground_option.set_text(0, "Ground Options")
	root_hit_stun.set_custom_bg_color(0, Color("#635166"))
	root_hit_stun.set_text(0, "Hit Stun")
	root_block_stun.set_custom_bg_color(0, Color("#51665a"))
	root_block_stun.set_text(0, 'Block Stun')

	for move: FighterAnimationData in move_list_sorted:
		if move.is_extension_only:
			continue
		var tree_item: TreeItem 
		match move.move_type:
			0:
				tree_item = root_movement.create_child()
			1:
				tree_item = root_attack.create_child()
			2:
				tree_item = root_ground_option.create_child()
			3:
				tree_item = root_hit_stun.create_child()
			4:
				tree_item = root_block_stun.create_child()

		self.add_to_tree(move, tree_item)

func add_to_tree(item: FighterAnimationData, tree_item: TreeItem) -> void:
	var move_list_item: MoveListItem = self.get_movelistitem_from_animationdata(item)
	
	match item.move_type:
		0:
			tree_item.set_custom_bg_color(0, Color('#515f66'))
		1:
			tree_item.set_custom_bg_color(0, Color('#665154'))
		2:
			tree_item.set_custom_bg_color(0, Color('#666551'))
		3:
			tree_item.set_custom_bg_color(0, Color('#635166'))
		4:
			tree_item.set_custom_bg_color(0, Color('#51665a'))

	move_list_item.tree_item = tree_item
	tree_item.set_text(0, move_list_item.move_name)
	tree_item.set_metadata(0, move_list_item)

	for extension: FighterAnimationData in item.extensions:
		var child_item: TreeItem = tree_item.create_child()
		self.add_to_tree(extension, child_item)

func compile_MoveListItem(item: MoveListItem) -> FighterAnimationData:
	var anim_data: FighterAnimationData = FighterAnimationData.new()
	var inputs: Array = []

	anim_data.is_extension_only = false

	anim_data.move_name = StringName(item.move_name)
	anim_data.move_type = item.get_node("%MoveType").selected
	anim_data.is_reference = item.is_reference

	anim_data.animation_name = StringName(item.get_animation_name())
	anim_data.look_at_enemy = item.get_node("%LookAtEnemy").button_pressed

	anim_data.add_inputs_arr(item.get_input_map())

	anim_data.no_input = item.get_node("%NoInput").button_pressed
	anim_data.hold_input = item.get_node("%HoldInput").button_pressed
	anim_data.non_attack = item.get_node("%NonAttackToggle").button_pressed
	anim_data.non_bufferable = item.get_node("%NonBufferable").button_pressed
	anim_data.side_context = item.get_node("%SideContext").selected

	if item.get_node('%RequiredState').text.is_empty():
		anim_data.required_state = []
	else:
		anim_data.required_state = item.get_node("%RequiredState").text.split(', ')

	if item.get_node("%ProhibitState").text.is_empty():
		anim_data.prohibit_state = []
	else:
		anim_data.prohibit_state = item.get_node("%ProhibitState").text.split(', ')

	anim_data.recovery_ref = StringName(item.get_node("%OnRecoveryRef").get_item_text(item.get_node("%OnRecoveryRef").selected))
	anim_data.block_animation = StringName(item.get_node("%OnBlockOpponentOption").text)
	anim_data.has_crouch_block_property = item.get_node("%OnCrouchBlockOpponentToggle").button_pressed
	anim_data.crouch_block_animation = StringName(item.get_node("%OnCrouchBlockOpponentOption").text)
	anim_data.hit_animation = StringName(item.get_node("%OnHitOpponentOption").text)
	anim_data.has_counter_property = item.get_node("%OnCounterOpponentToggle").button_pressed
	anim_data.counter_animation = StringName(item.get_node("%OnCounterOpponentOption").text)
	anim_data.back_hit_animation = StringName(item.get_node("%OnBackHitOpponentOption").text)

	anim_data.has_hit_recovery = item.get_node("%OnHitToggle").button_pressed
	anim_data.recovery_hit = StringName(item.get_node("%OnHitOption").text)
	anim_data.has_block_recovery = item.get_node("%OnBlockToggle").button_pressed
	anim_data.recovery_block = StringName(item.get_node("%OnBlockOption").text)
	anim_data.has_ch_recovery = item.get_node("%OnCounterToggle").button_pressed
	anim_data.recovery_ch = StringName(item.get_node("%OnCounterOption").text)
	anim_data.air_hit_animation = StringName(item.get_node("%OnAirHitOption").text)
	anim_data.ground_hit_animation = StringName(item.get_node("%OnGroundHitOption").text)

	anim_data.face_attacker_on_hit = item.get_node("%TargetFaceAttackerHit").button_pressed

	anim_data.player_states = item.get_state_data()

	anim_data.hitbox_data = item.get_hitbox_data()
	anim_data.hurtbox_data = item.get_hitbox_data(true)

	anim_data.pushback_force = FixedInt.FromFloat(item.get_node("%PushbackForce").value)
	anim_data.pushback_direction = FixedInt.Deg2Rads(FixedInt.FromFloat(item.get_node("%PushbackDirection").value))
	anim_data.launch_force = FixedInt.FromFloat(item.get_node("%LaunchForce").value)
	anim_data.launch_direction = FixedInt.Deg2Rads(FixedInt.FromFloat(item.get_node("%LaunchDirection").value))

	anim_data.pushback_mod_on_hit = FixedInt.FromFloat(item.get_node('%PushbackForceModOnHit').value)
	anim_data.pushback_mod_on_counter = FixedInt.FromFloat(item.get_node('%PushbackForceModOnCounter').value)
	anim_data.pushback_mod_on_ground_hit = FixedInt.FromFloat(item.get_node('%PushbackForceModOnGroundHit').value)
	anim_data.pushback_mod_on_block = FixedInt.FromFloat(item.get_node('%PushbackForceModOnBlock').value)

	anim_data.pushback_angle_on_hit = item.get_node("%ApplyPushbackAngleOnHit").button_pressed
	anim_data.pushback_angle_on_counter = item.get_node("%ApplyPushbackAngleOnCounter").button_pressed
	anim_data.pushback_angle_on_ground_hit = item.get_node("%ApplyPushbackAngleOnGroundHit").button_pressed
	anim_data.pushback_angle_on_block = item.get_node("%ApplyPushbackAngleOnBlock").button_pressed

	anim_data.extension_buffer_start = item.get_node("%ExtensionBufferStart").value
	anim_data.extension_execute_start = item.get_node("%ExtensionExecuteStart").value
	anim_data.extension_execute_end = item.get_node("%ExtensionExecuteEnd").value

	for extension: MoveListItem in item.get_node('%ExtensionMovelist').get_children():
		anim_data.extensions.append(self.compile_MoveListItem(extension))

	return anim_data

# =========================

func _on_MoveListItem_is_selected(move: MoveListItem) -> void:
	self.selected_item = move

	for item: MoveListItem in get_tree().get_nodes_in_group("MoveListItems"): #%MoveListView.get_child(0).get_children():
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

func _on_MoveListItem_request_animation_length(anim_name: String, item: MoveListItem) -> void:
	var anim: Animation = self.anim_player.get_animation(anim_name)
	item.set_animation_length_label(anim.length)

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

	for item: MoveListItem in get_tree().get_nodes_in_group("MoveListItems"): #%MoveListView.get_child(0).get_children():
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
		var anim_data: FighterAnimationData = self.compile_MoveListItem(item)
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
		%MoveListTree.clear()

func _on_move_list_tree_item_selected() -> void:
	var item: TreeItem = %MoveListTree.get_selected()
	var move_list_item: MoveListItem = item.get_metadata(0)
	if move_list_item != null: 
		move_list_item.select(true)
		%MoveListView.ensure_control_visible(move_list_item)
