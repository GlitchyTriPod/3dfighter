@tool
class_name Trail3D extends MeshInstance3D

var _points := []
var _widths := []
var _life_points := []

@export var trail_enabled := true

@export var from_width := 0.5
@export var to_width := 0.0
@export_range(0.5, 1.5) var scale_acceleration := 1.0

@export var motion_delta := 0.1
@export var life_span := 1.0

@export var start_color := Color(1,1,1,1)
@export var end_color := Color(1,1,1,0)

var _old_pos: Vector3

func _ready() -> void:
	self._old_pos = self.global_transform.origin
	self.mesh = ImmediateMesh.new()

func append_point() -> void:
	self._points.append(self.global_transform.origin)
	self._widths.append([
		self.global_basis.x * self.from_width,
		self.global_basis.x * self.from_width - self.global_basis.x * self.to_width
	])

	self._life_points.append(0.0)

func remove_point(i: int) -> void:
	self._points.remove_at(i)
	self._widths.remove_at(i)
	self._life_points.remove_at(i)

func _process(delta: float) -> void:
	var p := 0
	var max_points := self._points.size()

	while p < max_points:
		self._life_points[p] += delta
		if self._life_points[p] > self.life_span:
			self.remove_point(p)
			p -= 1
			if p < 0: p = 0

		max_points = self._points.size()
		p += 1

	self.mesh.clear_surfaces()

	if self._points.size() < 2:
		return

	self.mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(self._points.size()):
		var t := float(i) / (self._points.size() - 1.0)
		var current_color := self.start_color.lerp(self.end_color, 1 - t)
		self.mesh.surface_set_color(current_color)

		var current_width = self._widths[i][0] - pow(1 - t, self.scale_acceleration) * self._widths[i][1]

		var t0 := i / self._points.size()
		var t1 := t

		self.mesh.surface_set_uv(Vector2(t0, 0))
		self.mesh.surface_add_vertex(self.to_local(self._points[i] + current_width))
		self.mesh.surface_set_uv(Vector2(t1, 1))
		self.mesh.surface_add_vertex(self.to_local(self._points[i] - current_width))
	self.mesh.surface_end()
