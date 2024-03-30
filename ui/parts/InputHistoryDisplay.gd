extends HBoxContainer
class_name InputHistoryDisplay

@export var di_icons: Array

@onready var di_icon = %DI
@onready var frame_count_label = %FrameCount

var input_val = null

func _process(_d):
	if self.input_val == null:
		self.visible = false
		return
	self.visible = true

	match self.input_val.di:
		Fighter.DI_STATE.NEUTRAL:
			self.di_icon.texture = self.di_icons[8]
		Fighter.DI_STATE.UP:
			self.di_icon.texture = self.di_icons[3]
		Fighter.DI_STATE.UP_BACK:
			if self.input_val.screen_pos == "LEFT":
				self.di_icon.texture = self.di_icons[6]
			else:
				self.di_icon.texture = self.di_icons[7]
		Fighter.DI_STATE.BACK:
			if self.input_val.screen_pos == "LEFT":
				self.di_icon.texture = self.di_icons[1]
			else:
				self.di_icon.texture = self.di_icons[2]
		Fighter.DI_STATE.DOWN_BACK:
			if self.input_val.screen_pos == "LEFT":
				self.di_icon.texture = self.di_icons[4]
			else:
				self.di_icon.texture = self.di_icons[5]
		Fighter.DI_STATE.DOWN:
			self.di_icon.texture = self.di_icons[0]
		Fighter.DI_STATE.DOWN_FORWARD:
			if self.input_val.screen_pos == "LEFT":
				self.di_icon.texture = self.di_icons[5]
			else:
				self.di_icon.texture = self.di_icons[4]
		Fighter.DI_STATE.FORWARD:
			if self.input_val.screen_pos == "LEFT":
				self.di_icon.texture = self.di_icons[2]
			else:
				self.di_icon.texture = self.di_icons[1]
		Fighter.DI_STATE.UP_FORWARD:
			if self.input_val.screen_pos == "LEFT":
				self.di_icon.texture = self.di_icons[7]
			else:
				self.di_icon.texture = self.di_icons[6]

	self.frame_count_label.text = str(self.input_val.frame_count)