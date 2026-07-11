extends HBoxContainer
class_name InputHistoryDisplay

@export var di_icons: Array

@onready var di_icon: TextureRect = %DI
@onready var frame_count_label: Label = %FrameCount

var sibling: InputHistoryDisplay = null

var input_val: Dictionary[StringName, Variant] = {}

func _ready() -> void:
	var idx: int = self.get_index()
	if idx != 0:
		self.sibling = self.get_parent().get_child(idx - 1)

func _process(_d: float) -> void:
	if self.input_val.is_empty():
		self.visible = false
		return
	self.visible = true

	match self.input_val.di:
		Fighter.DI_STATE.NEUTRAL:
			self.di_icon.texture = self.di_icons[8]
		Fighter.DI_STATE.UP:
			self.di_icon.texture = self.di_icons[3]
		Fighter.DI_STATE.UP_BACK:
			if self.input_val.screen_pos == 1:
				self.di_icon.texture = self.di_icons[6]
			else:
				self.di_icon.texture = self.di_icons[7]
		Fighter.DI_STATE.BACK:
			if self.input_val.screen_pos == 1:
				self.di_icon.texture = self.di_icons[1]
			else:
				self.di_icon.texture = self.di_icons[2]
		Fighter.DI_STATE.DOWN_BACK:
			if self.input_val.screen_pos == 1:
				self.di_icon.texture = self.di_icons[4]
			else:
				self.di_icon.texture = self.di_icons[5]
		Fighter.DI_STATE.DOWN:
			self.di_icon.texture = self.di_icons[0]
		Fighter.DI_STATE.DOWN_FORWARD:
			if self.input_val.screen_pos == 1:
				self.di_icon.texture = self.di_icons[5]
			else:
				self.di_icon.texture = self.di_icons[4]
		Fighter.DI_STATE.FORWARD:
			if self.input_val.screen_pos == 1:
				self.di_icon.texture = self.di_icons[2]
			else:
				self.di_icon.texture = self.di_icons[1]
		Fighter.DI_STATE.UP_FORWARD:
			if self.input_val.screen_pos == 1:
				self.di_icon.texture = self.di_icons[7]
			else:
				self.di_icon.texture = self.di_icons[6]


	var up_tick: int = SyncManager.current_tick
	if self.sibling != null:
		up_tick = self.sibling.input_val.frame_start

	self.frame_count_label.text = str(up_tick - self.input_val.frame_start)
