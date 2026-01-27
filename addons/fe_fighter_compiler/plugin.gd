@tool
extends EditorPlugin

const scene: Resource = preload("res://addons/fe_fighter_compiler/dock/FighterCompilerDock.tscn")

var global: FighterCompilerGlobal

var dock: EditorDock

func _enable_plugin() -> void:
	# Add autoloads here.
	self.global = preload("res://addons/fe_fighter_compiler/FighterCompilerGlobal.gd").new()
	self.global.request_node_to_dock.connect(self.add_to_dock)
	self.global.request_remove_node_from_dock.connect(self.remove_from_dock)

func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func _enter_tree() -> void:	
	self.dock = EditorDock.new()
	self.dock.title = "Fighter Maker"
	self.dock.transient = true
	self.dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM

	var dock_content: FighterCompilerDock = scene.instantiate()
	dock_content.request_hitbox_menu.connect(self._on_dock_request_hitbox_menu)
	self.dock.add_child(dock_content)
	add_dock(self.dock)

func _exit_tree() -> void:
	remove_dock(self.dock)
	self.dock.free()

func add_to_dock(dock_slot, node) -> void:
	add_control_to_dock(dock_slot, node)

func remove_from_dock(node) -> void:
	remove_control_from_docks(node)
	node.free()

func _on_dock_request_hitbox_menu(hitbox: HitboxButton) -> void:
	self.global.create_hitbox_menu(hitbox)