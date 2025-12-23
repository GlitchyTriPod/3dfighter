@tool
extends HBoxContainer
class_name AnimationState

var state_name : String:
	get:
		return %StateName.text

var frame_start := 0:
	get:
		return int(%FrameStart.value)
var frame_end := 0:
	get:
		return int(%FrameEnd.value)

func _on_remove_button_button_up() -> void:
	self.visible = false
	self.free()


func _on_frame_start_value_changed(value: float) -> void:
	%FrameEnd.min_value = value
