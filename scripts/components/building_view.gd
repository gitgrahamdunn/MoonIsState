extends Node2D

const AssetFactory = preload("res://scripts/core/asset_factory.gd")

@export var entity_id: int = -1

var _hovered: bool = false

func _ready() -> void:
	add_to_group("building_views")
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()

func _exit_tree() -> void:
	remove_from_group("building_views")

func get_entity_id() -> int:
	return entity_id

func get_world_pos() -> Vector2:
	return global_position

func set_hovered(v: bool) -> void:
	if _hovered == v:
		return
	_hovered = v
	queue_redraw()

func _draw() -> void:
	var e: Dictionary = Sim.get_entity(entity_id)
	var def_id: StringName = e.get("def_id", &"") as StringName

	draw_circle(Vector2(3.0, 14.0), 18.0, Color(0.0, 0.0, 0.0, 0.18))
	var tex_key: StringName = &"bld_command_dome"
	if def_id == &"solar_array":
		tex_key = &"bld_solar_array"
	elif def_id == &"hls_lander":
		tex_key = &"bld_hls_lander"
	elif def_id == &"launchpad":
		tex_key = &"bld_launchpad"
	elif def_id == &"scrap_heap":
		tex_key = &"bld_scrap_heap"

	var tex: Texture2D = AssetFactory.get_tex(tex_key)
	draw_texture(tex, -tex.get_size() * 0.5)
	if _hovered:
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 40, Color(1.0, 0.9, 0.2, 0.9), 2.0)
	_draw_construction_overlay(e)

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
