extends Node2D

@export var radius: float = 18.0
@export var ring_color: Color = Color(0.3, 1.0, 0.3, 1.0)

var _selected: bool = false

func set_selected(is_selected: bool) -> void:
	if _selected == is_selected:
		return
	_selected = is_selected
	queue_redraw()

func _draw() -> void:
	if not _selected:
		return
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ring_color, 2.0)
