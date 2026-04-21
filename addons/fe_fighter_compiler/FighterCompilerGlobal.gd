@tool
class_name FighterCompilerGlobal

signal request_node_to_dock(dock_slot, node)
signal request_remove_node_from_dock(node)

const hitbox_menu: Resource = preload("res://addons/fe_fighter_compiler/dock/HitboxMenu.tscn")
const bake_velocity_menu: Resource = preload("res://addons/fe_fighter_compiler/dock/BakeVelocityMenu.tscn")

func create_hitbox_menu(hitbox: HitboxButton, idx: int, name: String, is_hurtbox: bool = false) -> void:
    var data: Dictionary = hitbox.get_data()
    var menu: Node = self.hitbox_menu.instantiate()

    (menu as HitboxMenu).data = data
    (menu as HitboxMenu).hitbox_button_id = idx
    (menu as HitboxMenu).hitbox_name = name
    (menu as HitboxMenu).is_hurtbox = is_hurtbox

    menu.connect("request_dock_removal", self.request_remove_menu)
    menu.connect("update_data", hitbox.update_data)
    menu.connect("request_hitbox_removal", hitbox._on_HitboxMenu_request_hitbox_removal)

    self.request_node_to_dock.emit(EditorPlugin.DOCK_SLOT_LEFT_UR, menu)

func request_remove_menu(node) -> void:
    self.request_remove_node_from_dock.emit(node)

func create_bake_velocity_menu() -> void:
    var menu: Node = self.bake_velocity_menu.instantiate()
    menu.connect("request_dock_removal", self.request_remove_menu)
    self.request_node_to_dock.emit(EditorPlugin.DOCK_SLOT_LEFT_UR, menu)
