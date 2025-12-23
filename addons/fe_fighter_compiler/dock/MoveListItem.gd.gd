@tool
extends PanelContainer
class_name MoveListItem

signal is_selected(source)

const animation_state = preload("res://addons/fe_fighter_compiler/dock/animation_state.tscn")
const hitbox_button = preload("res://addons/fe_fighter_compiler/dock/HitboxButton.tscn")

@export var default_animations: AnimationLibrary
@export var hit_animations: AnimationLibrary
@export var block_aniamtions: AnimationLibrary

var character_animations: AnimationLibrary

var anim_names: Array[StringName]:
	get:
		var arr = self.default_animations.get_animation_list() + \
			self.hit_animations.get_animation_list() + \
			self.block_aniamtions.get_animation_list()
		if self.character_animations != null:
			arr += self.character_animations.get_animation_list()
		return arr		

func _ready() -> void:
	for name: StringName in self.anim_names:
		%MoveAnimationOption.add_item(name)
	# for name: StringName in self.block_aniamtions: # used for stagger effects on blocked attacks
	# 	%OnBlockOption.add_item(name)
	for name: StringName in self.block_aniamtions:
		%OnBlockOpponentOption.add_item(name)
	for name: StringName in self.hit_animations:
		%OnHitOpponentOption.add_item(name)
		%OnCounterOpponentOption.add_item(name)
	%MoveData.folded = true

func deselect():
	%IsSelected.button_pressed = false

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

func _on_add_hurtbox_button_up() -> void:
	var button: HitboxButton = self.hitbox_button.instantiate()
	button.is_hurtbox = true
	%HurtboxGrid.add_child(button)


