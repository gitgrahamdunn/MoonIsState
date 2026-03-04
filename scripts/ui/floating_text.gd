extends Control

const LIFETIME_SEC: float = 0.8
const RISE_MIN: float = 20.0
const RISE_MAX: float = 40.0

var _elapsed: float = 0.0
var _start_position: Vector2 = Vector2.ZERO
var _rise_amount: float = 28.0

@onready var _label: Label = $Label

func setup(text_value: String, kind: StringName) -> void:
	_label.text = text_value
	_label.modulate = _color_for_kind(kind)

func _ready() -> void:
	_start_position = position
	_rise_amount = randf_range(RISE_MIN, RISE_MAX)

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clamp(_elapsed / LIFETIME_SEC, 0.0, 1.0)
	position = _start_position + Vector2(0.0, -(_rise_amount * t))
	modulate.a = 1.0 - t
	if _elapsed >= LIFETIME_SEC:
		queue_free()

func _color_for_kind(kind: StringName) -> Color:
	if kind == &"money":
		return Color(0.42, 1.0, 0.56, 1.0)
	if kind == &"resource":
		return Color(0.54, 0.86, 1.0, 1.0)
	if kind == &"warning":
		return Color(1.0, 0.45, 0.34, 1.0)
	return Color(1.0, 1.0, 1.0, 1.0)
