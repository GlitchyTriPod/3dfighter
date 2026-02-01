@tool
extends Control
class_name FighterCompilerDock

signal request_hitbox_menu(node: HitboxButton, idx: int, name: String)
signal animation_frame_changed(frame: float)

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

func load_animation_data() -> void:

	self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

	var animations: PackedStringArray = self.anim_player.get_animation_list()

	for i in animations.size():
		%AnimationSelector.add_item(animations[i])
		if animations[i] == self.anim_player.current_animation:
			%AnimationSelector.selected = i

	self.anim_player.seek(0.0)
	self.animation_frame_changed.emit(0.0)

func load_movelist_data() -> void:
	#zzz
	pass

# func _process(_delta: float) -> void:
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

func empty_hitbox_visuals():
	var spheres: Array = EditorInterface.get_edited_scene_root().get_node("AddonSpheres").get_children()
	for i: Node in spheres:
		i.queue_free()
	
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
			break

func _on_MoveListItem_is_unselected() -> void:
	pass # maybe ill use this later idk

func _on_animation_selector_item_selected(index: int) -> void:
	self.anim_player.current_animation = %AnimationSelector.get_item_text(index)
	self.anim_player.seek(0.0)
	self.animation_frame_changed.emit(0.0)

func _on_MoveListItem_request_hitbox_menu(hitbox: HitboxButton, idx: int, name: String) -> void:
	self.request_hitbox_menu.emit(hitbox, idx, name)

func _on_seek_forward_button_up() -> void:
	if self.anim_player.current_animation_position >= self.anim_player.current_animation_length:
		return

	self.anim_player.seek(
		clampf(self.anim_player.current_animation_position + self.tick_time,
			self.anim_player.current_animation_position, 
			self.anim_player.current_animation_length
		),
		true
	)
	self.animation_frame_changed.emit(self.anim_player.current_animation_position * 60)

func _on_seek_back_button_up() -> void:
	if self.anim_player.current_animation_position <= 0:
		return
	
	self.anim_player.seek(
		clampf(self.anim_player.current_animation_position - self.tick_time, 0.0, 99999.0),
		true
	)

	self.animation_frame_changed.emit(self.anim_player.current_animation_position * 60)

func _on_add_move_button_up() -> void:
	var item: MoveListItem = self.move_list_item.instantiate()

	item.is_selected.connect(self._on_MoveListItem_is_selected)
	item.is_unselected.connect(self._on_MoveListItem_is_unselected)
	item.request_hitbox_menu.connect(self._on_MoveListItem_request_hitbox_menu)

	self.animation_frame_changed.connect(item._on_dock_animation_frame_changed)

	%MoveListView.get_child(0).add_child(item)

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
		var anim_data := FighterAnimationData.new()
		var inputs = []

		anim_data.move_name = item.move_name
		anim_data.add_inputs_arr(item.get_input_map())
		anim_data.animation_name = item.get_animation_name()

		# add frame data here

		anim_data.hitbox_data = item.get_hitbox_data()
		anim_data.hurtbox_data = item.get_hitbox_data(true)

		anim_data.player_states = item.get_state_data()

		move_list.add_to_list(anim_data)

	# done?
	# -> send + apply data to fighter scene
	self.fighter.movelist = move_list

	toaster.push_toast("Movelist compiled! Saving to disk...")

	ResourceSaver.save(self.fighter.movelist, "res://character/movelists/%s_movelist.tres" % self.fighter.fighter_name)

	toaster.push_toast("Saved Movelist to disk.")

func _on_reattach_button_button_up() -> void:
	self.attach_to_fighter_scene()
	self.load_animation_data()
