extends Node2D

const BASE_SIZE: Vector2 = Vector2(64.0, 42.0)
const SHADOW_SIZE: Vector2 = Vector2(76.0, 20.0)

@export var entity_id: int = -1

func _ready() -> void:
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()
	queue_redraw()

func _on_entity_updated(updated_entity_id: int) -> void:
	if updated_entity_id != entity_id:
		return
	_update_from_sim()
	queue_redraw()

func _update_from_sim() -> void:
	if entity_id < 0:
		return
	var entity: Dictionary = Sim.get_entity(entity_id)
	if entity.is_empty():
		return
	global_position = entity.get("pos", global_position) as Vector2

func _draw() -> void:
	var e: Dictionary = Sim.get_entity(entity_id)
	if e.is_empty():
		return
	var def_id: StringName = e.get("def_id", &"") as StringName

	_draw_ellipse(Vector2(0.0, 28.0), SHADOW_SIZE.x * 0.5, SHADOW_SIZE.y * 0.5, Color(0.0, 0.0, 0.0, 0.2), 28)

	var base_rect: Rect2 = Rect2(Vector2(-BASE_SIZE.x * 0.5, -BASE_SIZE.y * 0.5), BASE_SIZE)
	draw_rect(base_rect, Color(0.63, 0.67, 0.74, 1.0), true)
	_draw_rect_outline(base_rect, Color(0.16, 0.18, 0.22, 1.0), 2.0)

	if def_id == &"command_dome":
		draw_circle(Vector2(0.0, -18.0), 15.0, Color(0.52, 0.78, 0.88, 0.8))
		draw_arc(Vector2(0.0, -18.0), 15.0, PI, TAU, 24, Color(0.16, 0.18, 0.22, 0.95), 2.0)
	elif def_id == &"solar_array":
		_draw_panel(Rect2(Vector2(-28.0, -16.0), Vector2(18.0, 8.0)))
		_draw_panel(Rect2(Vector2(-6.0, -12.0), Vector2(18.0, 8.0)))
		_draw_panel(Rect2(Vector2(16.0, -8.0), Vector2(18.0, 8.0)))

func _draw_panel(panel_rect: Rect2) -> void:
	draw_rect(panel_rect, Color(0.22, 0.34, 0.58, 1.0), true)
	_draw_rect_outline(panel_rect, Color(0.08, 0.10, 0.16, 0.95), 1.5)

func _draw_rect_outline(rect: Rect2, color: Color, width: float) -> void:
	var tl: Vector2 = rect.position
	var tr: Vector2 = Vector2(rect.end.x, rect.position.y)
	var br: Vector2 = rect.end
	var bl: Vector2 = Vector2(rect.position.x, rect.end.y)
	draw_line(tl, tr, color, width)
	draw_line(tr, br, color, width)
	draw_line(br, bl, color, width)
	draw_line(bl, tl, color, width)

func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, points: int = 24) -> void:
	var verts: PackedVector2Array = PackedVector2Array()
	for i: int in range(points):
		var angle: float = TAU * float(i) / float(points)
		var p: Vector2 = center + Vector2(cos(angle) * rx, sin(angle) * ry)
		verts.append(p)
	draw_polygon(verts, PackedColorArray([color]))
