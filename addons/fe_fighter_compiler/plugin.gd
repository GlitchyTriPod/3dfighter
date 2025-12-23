@tool
extends EditorPlugin

const dock = preload("res://addons/fe_fighter_compiler/dock/FighterCompilerDock.tscn")


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_control_to_bottom_panel(dock.instantiate(), "Fighter Maker")


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
