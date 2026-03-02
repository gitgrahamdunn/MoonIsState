extends Node2D

const BODY_RADIUS: float = 15.0
const SHADOW_SIZE: Vector2 = Vector2(26.0, 10.0)
const SELECTION_BASE_RADIUS: float = 26.0

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
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_ellipse(Vector2(0.0, 11.0), SHADOW_SIZE, Color(0.0, 0.0, 0.0, 0.28))

	var body_color: Color = Color(0.77, 0.86, 0.96, 1.0)
	var outline_color: Color = Color(0.14, 0.2, 0.28, 1.0)
	draw_circle(Vector2.ZERO, BODY_RADIUS, body_color)
	draw_arc(Vector2.ZERO, BODY_RADIUS, 0.0, TAU, 48, outline_color, 2.0)

	var visor_center: Vector2 = Vector2(0.0, -2.0)
	draw_circle(visor_center, 5.0, Color(0.3, 0.42, 0.56, 1.0))
	draw_arc(visor_center, 5.0, 0.0, TAU, 24, Color(0.64, 0.81, 0.95, 0.9), 1.6)

	if _selected:
		var pulse: float = sin(_t * 4.0) * 2.0
		var ring_radius: float = SELECTION_BASE_RADIUS + pulse
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, Color(0.62, 0.98, 0.62, 0.95), 2.0)

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

	var tip: Vector2 = direction * (BODY_RADIUS + 6.0)
	var side: Vector2 = direction.orthogonal() * 3.0
	var back: Vector2 = direction * (BODY_RADIUS - 1.0)
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
