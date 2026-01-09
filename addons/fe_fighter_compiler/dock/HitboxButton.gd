@tool
extends Button
class_name HitboxButton

signal clicked(source)

@export var is_hurtbox := false

var sphere_radius := 0

var x_pos := 0
var y_pos := 0
var z_pos := 0

var frame_start := 0
var frame_end := 0

var attack_height: int

var unblockable := false
var is_grab := false

var is_punch := false
var is_kick := false

func _ready() -> void:
	self.update_text()

func update_text() -> void:
	self.text = \
		"Radius: " + str(self.sphere_radius) + "\n" + \
		"X: " + str(self.x_pos) + "\n" + \
		"Y: " + str(self.y_pos) + "\n" + \
		"Z: " + str(self.z_pos) + "\n" + \
		"i" + str(self.frame_start) + " - i" + str(self.frame_end)

func _on_button_up() -> void:
	self.clicked.emit(self)

func get_data() -> Dictionary:
	return {
		"sphere_radius": self.sphere_radius,
		"x_pos": self.x_pos,
		"y_pos": self.y_pos,
		"z_pos": self.z_pos,
		"frame_start": self.frame_start,
		"frame_end": self.frame_end,
		"attack_height": self.attack_height,
		"unblockable": self.unblockable,
		"is_punch": self.is_punch,
		"is_kick": self.is_kick,
		"is_grab": self.is_grab
	}

func update_data(data: Dictionary):
	self.sphere_radius = data["sphere_radius"]
	self.x_pos = data["x_pos"]
	self.y_pos = data["y_pos"]
	self.z_pos = data["z_pos"]
	self.frame_start = data["frame_start"]
	self.frame_end = data["frame_end"]
	self.attack_height = data["attack_height"]
	self.unblockable = data['unblockable']
	self.is_punch = data['is_punch']
	self.is_kick = data['is_kick']
	self.is_grab = data['is_grab']
	self.update_text()