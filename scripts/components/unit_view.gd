extends Node2D

const BODY_SIZE: Vector2 = Vector2(22.0, 18.0)

@export var entity_id: int = -1

var _selected: bool = false

func _ready() -> void:
	add_to_group("unit_views")
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()

func _exit_tree() -> void:
	remove_from_group("unit_views")

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
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(2.0, 10.0), 10.0, Color(0.0, 0.0, 0.0, 0.2))

	var entity: Dictionary = Sim.get_entity(entity_id)
	var is_broken: bool = bool(entity.get("is_broken", false))
	var durability: float = float(entity.get("durability", 100.0))
	var durability_ratio: float = clamp(durability / 100.0, 0.0, 1.0)

	var body_color: Color = Color(0.62, 0.67, 0.74, 1.0)
	var outline_color: Color = Color(0.12, 0.14, 0.18, 1.0)
	var highlight_color: Color = Color(0.84, 0.88, 0.94, 1.0)
	if is_broken:
		body_color = Color(0.31, 0.31, 0.35, 1.0)
		highlight_color = Color(0.53, 0.45, 0.45, 1.0)
		outline_color = Color(0.42, 0.14, 0.14, 1.0)

	var body_rect: Rect2 = Rect2(-BODY_SIZE * 0.5, BODY_SIZE)
	draw_rect(body_rect, body_color, true)
	draw_rect(body_rect, outline_color, false, 2.0)
	var highlight_rect: Rect2 = Rect2(body_rect.position + Vector2(2.0, 2.0), Vector2(BODY_SIZE.x * 0.48, 4.0))
	draw_rect(highlight_rect, highlight_color, true)
	var visor_rect: Rect2 = Rect2(Vector2(-5.0, -2.0), Vector2(10.0, 5.0))
	draw_rect(visor_rect, Color(0.3, 0.44, 0.64, 1.0), true)
	draw_rect(visor_rect, Color(0.78, 0.9, 1.0, 0.8), false, 1.0)

	var durability_start: float = -PI * 0.5
	var durability_end: float = durability_start + (TAU * durability_ratio)
	draw_arc(Vector2.ZERO, 15.0, durability_start, durability_end, 20, Color(0.3, 0.94, 0.44, 0.9), 2.0)

	if is_broken:
		draw_line(Vector2(-6.0, -6.0), Vector2(6.0, 6.0), Color(1.0, 0.2, 0.2, 1.0), 2.0)
		draw_line(Vector2(-6.0, 6.0), Vector2(6.0, -6.0), Color(1.0, 0.2, 0.2, 1.0), 2.0)

	if _selected:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 1.0), 2.0)

	_draw_direction_indicator()

func _draw_direction_indicator() -> void:
	if entity_id < 0:
		return
	var e: Dictionary = Sim.get_entity(entity_id)
	if e.is_empty():
		return
	var has_move_target: bool = bool(e.get("has_move_target", false))
	if not has_move_target:
		return

	var pos: Vector2 = e.get("pos", global_position) as Vector2
	var target: Vector2 = e.get("move_target", pos) as Vector2
	var direction: Vector2 = (target - pos).normalized()
	if direction == Vector2.ZERO:
		return

	var tip: Vector2 = direction * 17.0
	var side: Vector2 = direction.orthogonal() * 4.0
	var back: Vector2 = direction * 10.0
	var points: PackedVector2Array = PackedVector2Array([tip, back + side, back - side])
	draw_colored_polygon(points, Color(0.95, 0.95, 1.0, 0.95))

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
