@tool
extends Sprite3D

@export_range(0, 5) var trail_life := 4:
	set(val):
		trail_life = val
		# if !Engine.is_editor_hint():
		# 	self._trail_life = val

@onready var _trail_life := 4:
	set(val):
		_trail_life = clampi(val, 0, 5)
		%TrailEmitter.num_points = self._trail_life

# @export_range(0, 100) var trail_length := 100:
# 	set(val):
# 		trail_length = val
# 		if Engine.is_editor_hint():
# 			self._trail_length = val

# @onready var _trail_length := self.trail_length:
# 	set(val):
# 		_trail_length = clampi(val, 0, 100)
# 		%GPUTrail3D.length = self._trail_length

func _ready() -> void:
	self.texture = self.texture.duplicate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if %TrailEmitter.num_points == 0 || self.trail_life == 0:	
		self.visible = false
	else:
		self.visible = true

	if !self.visible: return

	self.texture.width = 59 if self.texture.width == 64 else 64
	self.texture.height = 59 if self.texture.height == 64 else 64
