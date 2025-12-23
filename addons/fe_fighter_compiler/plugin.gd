@tool
extends EditorPlugin

const scene = preload("res://addons/fe_fighter_compiler/dock/FighterCompilerDock.tscn")

var dock

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:	
	self.dock = scene.instantiate()
	add_control_to_bottom_panel(self.dock, "Fighter Maker")


func _exit_tree() -> void:
	remove_control_from_docks(self.dock)
	self.dock.free()
