extends Node2D

signal blocked
signal missed

@export var radius: float = 90.0
@export var hit_forgiveness: float = 20.0
@export var circle_segments: int = 48

@onready var outer_ring: Line2D = $OuterRing
@onready var fill_circle: Polygon2D = $FillCircle

var _active: bool = false
var _elapsed: float = 0.0
var _duration: float = 1.0


func _ready() -> void:
	_build_circle_geometry()
	visible = false
	set_process(false)
	set_process_input(false)


func start_prompt(world_pos: Vector2, duration: float) -> void:
	global_position = world_pos
	_duration = maxf(duration, 0.05)
	_elapsed = 0.0
	_active = true
	fill_circle.scale = Vector2.ZERO
	visible = true
	set_process(true)
	set_process_input(true)


func cancel() -> void:
	_deactivate()


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	fill_circle.scale = Vector2.ONE * progress

	if progress >= 1.0:
		_deactivate()
		missed.emit()


func _input(event: InputEvent) -> void:
	if not _active:
		return

	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			var world_pos: Vector2 = get_canvas_transform().affine_inverse() * touch.position
			var local_pos: Vector2 = to_local(world_pos)
			if local_pos.length() <= (radius + hit_forgiveness):
				get_viewport().set_input_as_handled()
				_deactivate()
				blocked.emit()


func _deactivate() -> void:
	_active = false
	visible = false
	set_process(false)
	set_process_input(false)


func _build_circle_geometry() -> void:
	var pts := PackedVector2Array()
	pts.resize(circle_segments)
	for i in circle_segments:
		var angle := (TAU * i) / float(circle_segments)
		pts[i] = Vector2(cos(angle), sin(angle)) * radius

	outer_ring.points = pts
	outer_ring.closed = true
	fill_circle.polygon = pts
