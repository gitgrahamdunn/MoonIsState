extends Node2D

const BASE_SIZE: Vector2 = Vector2(50.0, 38.0)

@export var entity_id: int = -1

func _ready() -> void:
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()

func _draw() -> void:
	var e: Dictionary = Sim.get_entity(entity_id)
	var def_id: StringName = e.get("def_id", &"") as StringName

	draw_rect(Rect2(Vector2(-14.0, 12.0), Vector2(28.0, 8.0)), Color(0.0, 0.0, 0.0, 0.2), true)
	if def_id == &"solar_array":
		_draw_solar_array()
	elif def_id == &"launchpad":
		_draw_launchpad()
	elif def_id == &"scrap_heap":
		_draw_scrap_heap()
	else:
		_draw_command_dome()

	_draw_construction_overlay(e)

func _draw_command_dome() -> void:
	var body_rect: Rect2 = Rect2(Vector2(-BASE_SIZE.x * 0.5, -BASE_SIZE.y * 0.5), BASE_SIZE)
	draw_rect(body_rect, Color(0.44, 0.52, 0.64, 1.0), true)
	draw_rect(body_rect, Color(0.13, 0.17, 0.23, 1.0), false, 2.0)

	var corner_radius: float = 7.0
	draw_circle(body_rect.position + Vector2(corner_radius, corner_radius), corner_radius, Color(0.44, 0.52, 0.64, 1.0))
	draw_circle(body_rect.position + Vector2(body_rect.size.x - corner_radius, corner_radius), corner_radius, Color(0.44, 0.52, 0.64, 1.0))
	draw_circle(body_rect.position + Vector2(corner_radius, body_rect.size.y - corner_radius), corner_radius, Color(0.44, 0.52, 0.64, 1.0))
	draw_circle(body_rect.position + Vector2(body_rect.size.x - corner_radius, body_rect.size.y - corner_radius), corner_radius, Color(0.44, 0.52, 0.64, 1.0))

	draw_circle(Vector2(0.0, -22.0), 14.0, Color(0.58, 0.77, 0.92, 0.95))
	draw_arc(Vector2(0.0, -22.0), 14.0, PI, TAU, 32, Color(0.1, 0.16, 0.24, 1.0), 2.0)

func _draw_solar_array() -> void:
	var base_rect: Rect2 = Rect2(Vector2(-15.0, -10.0), Vector2(30.0, 20.0))
	draw_rect(base_rect, Color(0.46, 0.5, 0.56, 1.0), true)
	draw_rect(base_rect, Color(0.12, 0.14, 0.2, 1.0), false, 2.0)

	_draw_panel(Vector2(-20.0, -18.0), Vector2(22.0, 12.0))
	_draw_panel(Vector2(2.0, -20.0), Vector2(22.0, 12.0))
	_draw_panel(Vector2(24.0, -18.0), Vector2(18.0, 10.0))


func _draw_scrap_heap() -> void:
	var pile_rect: Rect2 = Rect2(Vector2(-28.0, -14.0), Vector2(56.0, 28.0))
	draw_rect(pile_rect, Color(0.36, 0.32, 0.3, 1.0), true)
	draw_rect(pile_rect, Color(0.1, 0.1, 0.1, 1.0), false, 2.0)
	draw_circle(Vector2(-12.0, -2.0), 6.0, Color(0.62, 0.62, 0.66, 1.0))
	draw_circle(Vector2(2.0, 1.0), 7.0, Color(0.56, 0.58, 0.62, 1.0))
	draw_circle(Vector2(14.0, -3.0), 5.0, Color(0.5, 0.52, 0.56, 1.0))

func _draw_launchpad() -> void:
	var platform_rect: Rect2 = Rect2(Vector2(-34.0, -16.0), Vector2(68.0, 32.0))
	draw_rect(platform_rect, Color(0.42, 0.45, 0.5, 1.0), true)
	draw_rect(platform_rect, Color(0.12, 0.14, 0.18, 1.0), false, 2.0)
	draw_line(Vector2(-28.0, 0.0), Vector2(28.0, 0.0), Color(0.92, 0.92, 0.98, 0.8), 2.0)
	var tower_rect: Rect2 = Rect2(Vector2(14.0, -34.0), Vector2(12.0, 26.0))
	draw_rect(tower_rect, Color(0.55, 0.58, 0.64, 1.0), true)
	draw_rect(tower_rect, Color(0.1, 0.12, 0.18, 1.0), false, 1.6)
	draw_circle(Vector2(-20.0, -3.0), 5.0, Color(0.78, 0.84, 0.92, 1.0))

func _draw_panel(position: Vector2, size: Vector2) -> void:
	var panel_rect: Rect2 = Rect2(position, size)
	draw_rect(panel_rect, Color(0.22, 0.43, 0.72, 0.98), true)
	draw_rect(panel_rect, Color(0.62, 0.84, 1.0, 0.9), false, 1.5)
	var grid_y: float = panel_rect.position.y + panel_rect.size.y * 0.5
	draw_line(Vector2(panel_rect.position.x, grid_y), Vector2(panel_rect.end.x, grid_y), Color(0.7, 0.9, 1.0, 0.55), 1.0)

func _draw_construction_overlay(entity: Dictionary) -> void:
	var is_constructing: bool = bool(entity.get("is_constructing", false))
	if not is_constructing:
		return
	var total: float = float(entity.get("build_total", 0.0))
	var remaining: float = float(entity.get("build_remaining", 0.0))
	var ratio: float = 1.0
	if total > 0.0:
		ratio = clamp(1.0 - (remaining / total), 0.0, 1.0)
	var overlay_rect: Rect2 = Rect2(Vector2(-36.0, -26.0), Vector2(72.0, 52.0))
	draw_rect(overlay_rect, Color(0.15, 0.16, 0.2, 0.35), true)
	for i: int in range(-48, 48, 10):
		draw_line(Vector2(float(i), -26.0), Vector2(float(i) + 20.0, 26.0), Color(0.95, 0.82, 0.2, 0.26), 3.0)
	draw_arc(Vector2.ZERO, 26.0, -PI * 0.5, (-PI * 0.5) + (TAU * ratio), 48, Color(0.1, 1.0, 0.2, 0.95), 4.0)

func _on_entity_updated(updated_entity_id: int) -> void:
	if updated_entity_id != entity_id:
		return
	_update_from_sim()

func _update_from_sim() -> void:
	if entity_id < 0:
		return
	var entity: Dictionary = Sim.get_entity(entity_id)
	if entity.is_empty():
		return
	global_position = entity.get("pos", global_position) as Vector2
	queue_redraw()
