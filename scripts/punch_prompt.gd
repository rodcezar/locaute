extends Node2D

signal punched(direction: Vector2)
signal missed

@export var min_swipe_distance: float = 110.0
@export var start_hit_radius: float = 180.0
@export var min_direction_dot: float = 0.72
@export var require_start_near_arrow: bool = false

@onready var arrow_visual: Polygon2D = $ArrowVisual

var _active: bool = false
var _elapsed: float = 0.0
var _duration: float = 1.2
var _target_dir: Vector2 = Vector2.RIGHT

var _tracked_finger: int = -1
var _drag_start_world: Vector2 = Vector2.ZERO


func _ready() -> void:
	_build_arrow_geometry()
	visible = false
	set_process(false)
	set_process_input(false)


func start_prompt(world_pos: Vector2, direction: Vector2, duration: float) -> void:
	global_position = world_pos
	_target_dir = direction.normalized()
	arrow_visual.rotation = _target_dir.angle()
	_duration = maxf(duration, 0.05)
	_elapsed = 0.0
	_tracked_finger = -1
	_active = true
	visible = true
	set_process(true)
	set_process_input(true)


func cancel() -> void:
	_deactivate()


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	var pulse := 1.0 + 0.08 * sin(_elapsed * 16.0)
	arrow_visual.scale = Vector2.ONE * pulse

	if _elapsed >= _duration:
		_deactivate()
		missed.emit()


func _input(event: InputEvent) -> void:
	if not _active:
		return

	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		var world_pos: Vector2 = get_canvas_transform().affine_inverse() * touch.position
		if touch.pressed and _tracked_finger == -1:
			if not require_start_near_arrow or to_local(world_pos).length() <= start_hit_radius:
				_tracked_finger = touch.index
				_drag_start_world = world_pos
				get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _tracked_finger:
			_tracked_finger = -1

	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _tracked_finger:
			var world_pos: Vector2 = get_canvas_transform().affine_inverse() * drag.position
			var drag_vec: Vector2 = world_pos - _drag_start_world
			if drag_vec.length() >= min_swipe_distance:
				if drag_vec.normalized().dot(_target_dir) >= min_direction_dot:
					get_viewport().set_input_as_handled()
					_deactivate()
					punched.emit(_target_dir)
				else:
					_tracked_finger = -1


func _deactivate() -> void:
	_active = false
	_tracked_finger = -1
	visible = false
	set_process(false)
	set_process_input(false)


func _build_arrow_geometry() -> void:
	if not arrow_visual.polygon.is_empty():
		return
	arrow_visual.polygon = PackedVector2Array([
		Vector2(-80, -20),
		Vector2(20, -20),
		Vector2(20, -50),
		Vector2(95, 0),
		Vector2(20, 50),
		Vector2(20, 20),
		Vector2(-80, 20),
	])
