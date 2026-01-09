@tool
class_name FighterCompilerGlobal

signal request_node_to_dock(dock_slot, node)
signal request_remove_node_from_dock(node)

const hitbox_menu = preload("res://addons/fe_fighter_compiler/dock/HitboxMenu.tscn")

func create_hitbox_menu(hitbox: HitboxButton) -> void:
    var data = hitbox.get_data()
    var menu: HitboxMenu = self.hitbox_menu.instantiate()
    menu.request_dock_removal.connect(self.request_remove_hitbox_menu)
    menu.update_data.connect(hitbox.update_data)

    self.request_node_to_dock.emit(EditorPlugin.DOCK_SLOT_LEFT_UL)

func request_remove_hitbox_menu(node) -> void:
    self.request_remove_node_from_dock.emit(node)
