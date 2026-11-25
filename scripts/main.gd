extends Node2D

const PLAYFIELD_CENTER := Vector2(360.0, 640.0)
const SWIPE_DIRECTIONS: Array[Vector2] = [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2(-1.0, -1.0),
	Vector2(1.0, -1.0),
]

@onready var opponent: Node2D = $Opponent
@onready var opponent_body: ColorRect = $Opponent/Body
@onready var block_prompt: Node2D = $BlockPrompt
@onready var punch_prompt: Node2D = $PunchPrompt
@onready var action_timer: Timer = $ActionTimer
@onready var status_label: Label = $HUD/StatusLabel

var _opponent_base_pos := Vector2(360.0, 560.0)
var _player_hp: int = 5
var _enemy_hp: int = 10


func _ready() -> void:
	_opponent_base_pos = opponent.position
	_update_hud("GET READY...")
	action_timer.start(1.0)


func _on_action_timer_timeout() -> void:
	if randf() < 0.5:
		_spawn_block()
	else:
		_spawn_punch()


func _spawn_block() -> void:
	_update_hud("INCOMING! TAP THE RED CIRCLE!")
	opponent_body.color = Color("#ff8844")
	var offset := Vector2(randf_range(-180.0, 180.0), randf_range(-180.0, 220.0))
	block_prompt.start_prompt(PLAYFIELD_CENTER + offset, 1.1)


func _spawn_punch() -> void:
	_update_hud("OPENING! SWIPE ALONG THE GREEN ARROW!")
	opponent_body.color = Color("#c84b4b")
	var dir: Vector2 = SWIPE_DIRECTIONS.pick_random()
	var offset := Vector2(randf_range(-120.0, 120.0), randf_range(-80.0, 180.0))
	punch_prompt.start_prompt(PLAYFIELD_CENTER + offset, dir, 1.25)


func _on_block_prompt_blocked() -> void:
	_update_hud("BLOCKED!")
	_flash_opponent(Color("#5599ff"))
	action_timer.start(0.75)


func _on_block_prompt_missed() -> void:
	_player_hp = maxi(_player_hp - 1, 0)
	_update_hud("HIT BY ENEMY!")
	_flash_opponent(Color("#ff2222"))
	action_timer.start(0.9)


func _on_punch_prompt_punched(direction: Vector2) -> void:
	_enemy_hp = maxi(_enemy_hp - 1, 0)
	_update_hud("NICE PUNCH!")
	var tween := create_tween()
	opponent.position = _opponent_base_pos + direction * 35.0
	tween.tween_property(opponent, "position", _opponent_base_pos, 0.18).set_trans(Tween.TRANS_BACK)
	_flash_opponent(Color.WHITE)
	action_timer.start(0.7)


func _on_punch_prompt_missed() -> void:
	_update_hud("TOO SLOW!")
	action_timer.start(0.75)


func _flash_opponent(flash_color: Color) -> void:
	opponent_body.color = flash_color
	var tween := create_tween()
	tween.tween_property(opponent_body, "color", Color("#c84b4b"), 0.2)


func _update_hud(message: String) -> void:
	status_label.text = "YOU: %d   |   FOE: %d\n%s" % [_player_hp, _enemy_hp, message]
