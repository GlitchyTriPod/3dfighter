@tool
extends Button
class_name HitboxButton

@export var is_hurtbox := false

var sphere_radius := 0

var x_pos := 0
var y_pos := 0
var z_pos := 0

var frame_start := 0
var frame_end := 0

var attack_height: int

var unblockable := false

func update_text() -> void:
    self.text = \
        "Radius: " + str(self.sphere_radius) + "\n" + \
        "X: " + str(self.x_pos) + "\n" + \
        "Y: " + str(self.y_pos) + "\n" + \
        "Z: " + str(self.z_pos) + "\n" + \
        "i" + str(self.frame_start) + " - i" + str(self.frame_end)