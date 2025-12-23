@tool
extends Control
class_name FighterCompilerDock

var animation_list := []

func _process(_delta: float) -> void:
    if EditorInterface.get_edited_scene_root() is FighterCompilerDock:
        return

    if !EditorInterface.get_edited_scene_root() is Fighter:
        %SelectFighterLabel.visible = true
        return
    %SelectFighterLabel.visible = false