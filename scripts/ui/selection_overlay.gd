extends Control

var selection_rect: Rect2 = Rect2()
var visible_rect: bool = false

func set_drag_rect(start_pos: Vector2, end_pos: Vector2) -> void:
	selection_rect = Rect2(start_pos, end_pos - start_pos).abs()
	visible_rect = true
	queue_redraw()

func clear_drag_rect() -> void:
	visible_rect = false
	queue_redraw()

func _draw() -> void:
	if not visible_rect:
		return
	draw_rect(selection_rect, Color(0.3, 0.8, 1.0, 0.15), true)
	draw_rect(selection_rect, Color(0.3, 0.8, 1.0, 0.9), false, 2.0)
