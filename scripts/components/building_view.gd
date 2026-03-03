extends Node2D

const BASE_SIZE: Vector2 = Vector2(50.0, 38.0)

@export var entity_id: int = -1

func _ready() -> void:
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()

func _draw() -> void:
	var e: Dictionary = Sim.get_entity(entity_id)
	var def_id: StringName = e.get("def_id", &"") as StringName

	draw_circle(Vector2(3.0, 14.0), 18.0, Color(0.0, 0.0, 0.0, 0.18))
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
	var body_rect: Rect2 = Rect2(Vector2(-23.0, -16.0), Vector2(46.0, 30.0))
	var body_color: Color = Color(0.52, 0.56, 0.63, 1.0)
	var outline_color: Color = Color(0.12, 0.14, 0.18, 1.0)
	draw_rect(body_rect, body_color, true)
	draw_rect(body_rect, outline_color, false, 2.0)
	draw_rect(Rect2(body_rect.position + Vector2(2.0, 2.0), Vector2(20.0, 5.0)), Color(0.75, 0.78, 0.84, 1.0), true)

	draw_circle(Vector2(0.0, -18.0), 14.0, Color(0.66, 0.73, 0.81, 1.0))
	draw_arc(Vector2(0.0, -18.0), 14.0, 0.0, TAU, 32, outline_color, 2.0)
	draw_rect(Rect2(Vector2(-7.0, 1.0), Vector2(14.0, 11.0)), Color(0.2, 0.23, 0.29, 1.0), true)
	draw_rect(Rect2(Vector2(-7.0, 1.0), Vector2(14.0, 11.0)), outline_color, false, 1.5)

func _draw_solar_array() -> void:
	var base_rect: Rect2 = Rect2(Vector2(-18.0, -8.0), Vector2(36.0, 20.0))
	draw_rect(base_rect, Color(0.46, 0.48, 0.53, 1.0), true)
	draw_rect(base_rect, Color(0.12, 0.14, 0.18, 1.0), false, 2.0)
	draw_rect(Rect2(Vector2(-6.0, -2.0), Vector2(12.0, 10.0)), Color(0.21, 0.23, 0.27, 1.0), true)

	_draw_panel(Vector2(-38.0, -18.0), Vector2(20.0, 12.0))
	_draw_panel(Vector2(-14.0, -22.0), Vector2(28.0, 12.0))
	_draw_panel(Vector2(18.0, -18.0), Vector2(20.0, 12.0))

func _draw_scrap_heap() -> void:
	var pile_rect: Rect2 = Rect2(Vector2(-28.0, -14.0), Vector2(56.0, 28.0))
	draw_rect(pile_rect, Color(0.33, 0.3, 0.29, 1.0), true)
	draw_rect(pile_rect, Color(0.11, 0.11, 0.11, 1.0), false, 2.0)
	draw_rect(Rect2(Vector2(-24.0, -10.0), Vector2(18.0, 8.0)), Color(0.54, 0.56, 0.6, 1.0), true)
	draw_rect(Rect2(Vector2(-2.0, -4.0), Vector2(14.0, 9.0)), Color(0.44, 0.47, 0.52, 1.0), true)
	draw_circle(Vector2(17.0, -2.0), 6.0, Color(0.58, 0.6, 0.65, 1.0))

func _draw_launchpad() -> void:
	var platform_rect: Rect2 = Rect2(Vector2(-34.0, -16.0), Vector2(68.0, 32.0))
	draw_rect(platform_rect, Color(0.43, 0.46, 0.5, 1.0), true)
	draw_rect(platform_rect, Color(0.12, 0.14, 0.18, 1.0), false, 2.0)
	draw_rect(Rect2(Vector2(-26.0, -2.0), Vector2(52.0, 4.0)), Color(0.86, 0.86, 0.9, 0.9), true)
	var tower_rect: Rect2 = Rect2(Vector2(16.0, -33.0), Vector2(12.0, 24.0))
	draw_rect(tower_rect, Color(0.54, 0.57, 0.63, 1.0), true)
	draw_rect(tower_rect, Color(0.1, 0.12, 0.16, 1.0), false, 2.0)
	draw_rect(Rect2(tower_rect.position + Vector2(2.0, 2.0), Vector2(6.0, 4.0)), Color(0.78, 0.82, 0.88, 1.0), true)

func _draw_panel(position: Vector2, size: Vector2) -> void:
	var panel_rect: Rect2 = Rect2(position, size)
	draw_rect(panel_rect, Color(0.18, 0.35, 0.58, 1.0), true)
	draw_rect(panel_rect, Color(0.63, 0.84, 1.0, 0.9), false, 2.0)
	for stripe: int in range(1, 4):
		var x: float = panel_rect.position.x + (panel_rect.size.x * float(stripe) * 0.25)
		draw_line(Vector2(x, panel_rect.position.y + 1.0), Vector2(x, panel_rect.end.y - 1.0), Color(0.68, 0.88, 1.0, 0.45), 1.0)

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
