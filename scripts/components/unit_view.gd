extends Node2D

const BODY_R: float = 15.0
const SHADOW_SIZE: Vector2 = Vector2(28.0, 10.0)

@export var entity_id: int = -1

var _selected: bool = false
var _t: float = 0.0

func _ready() -> void:
	add_to_group("unit_views")
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()

func _exit_tree() -> void:
	remove_from_group("unit_views")

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func get_entity_id() -> int:
	return entity_id

func get_world_pos() -> Vector2:
	return global_position

func set_selected(v: bool) -> void:
	if _selected == v:
		return
	_selected = v
	queue_redraw()

func _draw() -> void:
	_draw_ellipse(Vector2(0.0, BODY_R + 10.0), SHADOW_SIZE.x * 0.5, SHADOW_SIZE.y * 0.5, Color(0.0, 0.0, 0.0, 0.22), 24)
	draw_circle(Vector2.ZERO, BODY_R, Color(0.85, 0.88, 0.92, 1.0))
	draw_arc(Vector2.ZERO, BODY_R, 0.0, TAU, 48, Color(0.15, 0.18, 0.22, 1.0), 2.0)
	draw_circle(Vector2(4.0, -3.0), 5.0, Color(0.25, 0.55, 0.70, 0.75))

	if _selected:
		var pulse: float = sin(_t * 4.0) * 2.0
		var r: float = BODY_R + 12.0 + pulse
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.95), 2.0)

	var e: Dictionary = Sim.get_entity(entity_id)
	var has_t: bool = bool(e.get("has_move_target", false))
	if has_t:
		var target: Vector2 = e.get("move_target", Vector2.ZERO) as Vector2
		var dir: Vector2 = target - global_position
		if dir.length() > 0.001:
			dir = dir.normalized()
			draw_line(Vector2.ZERO, dir * (BODY_R + 8.0), Color(0.15, 0.18, 0.22, 0.9), 2.0)
			var tip: Vector2 = dir * (BODY_R + 10.0)
			var left: Vector2 = tip + dir.orthogonal() * 4.0 - dir * 4.0
			var right: Vector2 = tip - dir.orthogonal() * 4.0 - dir * 4.0
			draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([Color(0.15, 0.18, 0.22, 0.9)]))

func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, points: int = 24) -> void:
	var verts: PackedVector2Array = PackedVector2Array()
	for i: int in range(points):
		var angle: float = TAU * float(i) / float(points)
		var p: Vector2 = center + Vector2(cos(angle) * rx, sin(angle) * ry)
		verts.append(p)
	draw_polygon(verts, PackedColorArray([color]))

func _on_entity_updated(updated_entity_id: int) -> void:
	if updated_entity_id != entity_id:
		return
	_update_from_sim()

func _update_from_sim() -> void:
	if entity_id < 0:
		return
	var e: Dictionary = Sim.get_entity(entity_id)
	if e.is_empty():
		return
	global_position = e.get("pos", global_position) as Vector2
