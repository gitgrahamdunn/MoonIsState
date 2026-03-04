extends Node2D

const LIFETIME_SEC: float = 0.5

var _elapsed: float = 0.0
var _star_count: int = 10
var _base_radius: float = 8.0

func _ready() -> void:
	_star_count = randi_range(8, 12)
	_base_radius = randf_range(6.0, 10.0)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= LIFETIME_SEC:
		queue_free()

func _draw() -> void:
	var t: float = clamp(_elapsed / LIFETIME_SEC, 0.0, 1.0)
	var alpha: float = 1.0 - t
	var radius: float = lerp(_base_radius, _base_radius + 16.0, t)
	for i: int in range(_star_count):
		var angle: float = TAU * (float(i) / float(_star_count))
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var star_pos: Vector2 = dir * radius
		_draw_star(star_pos, 2.0 + (1.2 * (1.0 - t)), Color(1.0, 0.96, 0.6, alpha))

func _draw_star(center: Vector2, half_size: float, color: Color) -> void:
	draw_line(center + Vector2(-half_size, 0.0), center + Vector2(half_size, 0.0), color, 1.2, true)
	draw_line(center + Vector2(0.0, -half_size), center + Vector2(0.0, half_size), color, 1.2, true)
