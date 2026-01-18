@tool
extends Control
class_name FighterCompilerDock

signal request_hitbox_menu(node)
signal animation_frame_changed(frame: float)

const move_list_item = preload('res://addons/fe_fighter_compiler/dock/MoveListItem.tscn')

var anim_player: NetworkAnimationPlayer

var fighter: Fighter

var process := true

func _ready() -> void:
	self.process = true

	var root = EditorInterface.get_edited_scene_root()

	if root is not Fighter:
		return

	self.fighter = root

	self.anim_player = root.get_node("NetworkAnimationPlayer")

	var animations : PackedStringArray = self.anim_player.get_animation_list()

	for i in animations.size():
		%AnimationSelector.add_item(animations[i])
		if animations[i] == self.anim_player.current_animation:
			%AnimationSelector.selected = i

	self.anim_player.seek(0.0)
	self.animation_frame_changed.emit(0.0)

func _process(_delta: float) -> void:
	if !process:
		return

	if EditorInterface.get_edited_scene_root() is FighterCompilerDock:
		return

	if EditorInterface.get_edited_scene_root() is not Fighter:
		%SelectFighterLabel.visible = true
		%MoveListControls.visible = false
		%MoveListView.visible = false
		return
	%SelectFighterLabel.visible = false
	%MoveListControls.visible = true
	%MoveListView.visible = true

	if EditorInterface.get_edited_scene_root() != self.fighter:
		self.process = false
		get_tree().reload_current_scene()

func empty_hitbox_visuals():
	var spheres = EditorInterface.get_edited_scene_root().get_node("AddonSpheres").get_children()
	for i in spheres:
		i.queue_free()

func _on_add_move_button_up() -> void:
	var item: MoveListItem = self.move_list_item.instantiate()
	item.is_selected.connect(self._on_MoveListItem_is_selected)
	item.is_unselected.connect(self._on_MoveListItem_is_unselected)
	item.request_hitbox_menu.connect(self._on_MoveListItem_request_hitbox_menu)

	self.animation_frame_changed.connect(item._on_dock_animation_frame_changed)

	%MoveListView.add_child(item)
	
func _on_MoveListItem_is_selected(move: MoveListItem) -> void:
	for item: MoveListItem in %MoveListView.get_child(0).get_children():
		if item == move:
			continue
		item.deselect()

func _on_MoveListItem_is_unselected() -> void:
	pass

func _on_MoveListItem_request_hitbox_menu(hitbox: HitboxButton) -> void:
	self.request_hitbox_menu.emit(hitbox)

func _on_seek_back_button_up() -> void:
	if self.anim_player.current_animation_position <= 0:
		return
	
	self.anim_player.seek(
		clampf(self.anim_player.current_animation_position - SyncManager.tick_time, 0.0, 99999.0)
	)

	self.animation_frame_changed.emit(self.anim_player.current_animation_position * 60)

func _on_remove_move_button_up() -> void:
	self.anim_player.seek(
		clampf(self.anim_player.current_animation_position + SyncManager.tick_time, 0.0, 99999.0)
	)

	self.animation_frame_changed.emit(self.anim_player.current_animation_position * 60)

func _on_animation_frame_changed(frame: float) -> void:
	%FrameLabel.text = "Frame: " + str(frame)

func _on_compile_movelist_button_button_up() -> void:
	var toaster = EditorInterface.get_editor_toaster()
	toaster.push_toast("Compiling Movelist...")

	var move_list := FighterMovelist.new()

	for item: MoveListItem in %MoveListView.get_child(0).get_children():
		var anim_data := FighterAnimationData.new()
		var inputs = []

		anim_data.move_name = item.move_name
		anim_data.add_inputs(item.get_input_map())
		anim_data.animation_name = item.get_animation_name()

		# add frame data here

		anim_data.hitbox_data = item.get_hitbox_data()
		anim_data.hurtbox_data = item.get_hitbox_data(true)

		anim_data.player_states = item.get_state_data()

		move_list.add_to_list(anim_data)

	# done?