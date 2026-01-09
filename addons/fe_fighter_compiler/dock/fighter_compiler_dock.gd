@tool
extends Control
class_name FighterCompilerDock

signal request_hitbox_menu(node)
signal animation_frame_changed(frame)

const move_list_item = preload('res://addons/fe_fighter_compiler/dock/MoveListItem.tscn')

var anim_player: NetworkAnimationPlayer

func _ready() -> void:
	var root = EditorInterface.get_edited_scene_root()

	if root is not Fighter:
		return

	self.anim_player = root.get_node("NetworkAnimationPlayer")

	var animations : PackedStringArray = self.anim_player.get_animation_list()

	for i in animations.size():
		%AnimationSelector.add_item(animations[i])
		if animations[i] == self.anim_player.current_animation:
			%AnimationSelector.selected = i

	self.anim_player.seek(0.0)
	%FrameLabel.text = "Frame: 0"
	self.animation_frame_changed.emit(0.0)

func _process(_delta: float) -> void:
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

func empty_hitbox_visuals():
	var spheres = EditorInterface.get_edited_scene_root().get_node("AddonSpheres").get_children()
	for i in spheres:
		i.queue_free()

func _on_add_move_button_up() -> void:
	var item: MoveListItem = self.move_list_item.instantiate()
	item.is_selected.connect(self._on_MoveListItem_is_selected)
	item.is_unselected.connect(self._on_MoveListItem_is_unselected)
	item.request_hitbox_menu.connect(self._on_MoveListItem_request_hitbox_menu)
	%MoveListView.add_child(item)
	
func _on_MoveListItem_is_selected(move: MoveListItem) -> void:
	for item: MoveListItem in %MoveListView.get_child(0):
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

	%FrameLabel.text = "Frame: " + str(self.anim_player.current_animation_position * 60)
	self.animation_frame_changed.emit(self.anim_player.current_animation_position * 60)

func _on_remove_move_button_up() -> void:
	self.anim_player.seek(
		clampf(self.anim_player.current_animation_position + SyncManager.tick_time, 0.0, 99999.0)
	)

	%FrameLabel.text = "Frame: " + str(self.anim_player.current_animation_position * 60)
	self.animation_frame_changed.emit(self.anim_player.current_animation_position * 60)
