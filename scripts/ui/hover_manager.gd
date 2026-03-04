extends Node

signal hovered_entity_changed(entity_id: int, kind: StringName)

const HOVER_RADIUS: float = 44.0

@export var world_path: NodePath

var _main: Node = null
var _hud: Control = null
var _hovered_entity_id: int = -1
var _hovered_kind: StringName = &""
var _hovered_view: Node = null

func _ready() -> void:
	if _main == null:
		_main = get_tree().current_scene
	if _hud == null and _main != null:
		_hud = _main.get_node_or_null("UILayer/HUD") as Control

func set_context(main_node: Node, hud_node: Control) -> void:
	_main = main_node
	_hud = hud_node

func _process(_delta: float) -> void:
	if _main == null or not _main.has_method("get_world_mouse_pos"):
		return
	var world_pos: Vector2 = _main.call("get_world_mouse_pos") as Vector2
	var screen_pos: Vector2 = get_viewport().get_mouse_position()
	var best_view: Node = _find_best_hover_view(world_pos)
	_apply_hover(best_view, screen_pos)

func _find_best_hover_view(world_pos: Vector2) -> Node:
	var best_view: Node = null
	var best_d2: float = HOVER_RADIUS * HOVER_RADIUS
	var groups: Array[StringName] = [&"unit_views", &"building_views"]
	for group_name: StringName in groups:
		var views: Array = get_tree().get_nodes_in_group(String(group_name))
		for view: Variant in views:
			var node: Node = view as Node
			if node == null:
				continue
			if not node.has_method("get_world_pos"):
				continue
			var view_world_pos: Vector2 = node.call("get_world_pos") as Vector2
			var d2: float = view_world_pos.distance_squared_to(world_pos)
			if d2 < best_d2:
				best_d2 = d2
				best_view = node
	return best_view

func _apply_hover(best_view: Node, screen_pos: Vector2) -> void:
	if _hovered_view != null and _hovered_view != best_view and _hovered_view.has_method("set_hovered"):
		_hovered_view.call("set_hovered", false)

	if best_view == null:
		if _hovered_view != null:
			_hovered_view = null
		_set_hovered_entity(-1, &"")
		if _hud != null and _hud.has_method("hide_tooltip"):
			_hud.call("hide_tooltip")
		return

	if best_view.has_method("set_hovered"):
		best_view.call("set_hovered", true)
	_hovered_view = best_view

	var entity_id: int = -1
	if best_view.has_method("get_entity_id"):
		entity_id = int(best_view.call("get_entity_id"))
	if entity_id <= 0:
		_set_hovered_entity(-1, &"")
		if _hud != null and _hud.has_method("hide_tooltip"):
			_hud.call("hide_tooltip")
		return

	var entity: Dictionary = Sim.get_entity(entity_id)
	var kind: StringName = entity.get("kind", &"") as StringName
	_set_hovered_entity(entity_id, kind)

	if _hud != null and _hud.has_method("show_tooltip"):
		var tooltip_text: String = _build_tooltip_text(entity)
		_hud.call("show_tooltip", tooltip_text, screen_pos + Vector2(14.0, 18.0))

func _set_hovered_entity(entity_id: int, kind: StringName) -> void:
	if _hovered_entity_id == entity_id and _hovered_kind == kind:
		return
	_hovered_entity_id = entity_id
	_hovered_kind = kind
	emit_signal("hovered_entity_changed", _hovered_entity_id, _hovered_kind)

func _build_tooltip_text(entity: Dictionary) -> String:
	var def_id: StringName = entity.get("def_id", &"") as StringName
	var kind: StringName = entity.get("kind", &"") as StringName
	var display_name: String = String(def_id)
	if kind == &"building":
		var bdef: BuildingDef = DataDB.get_building_def(def_id)
		if bdef != null and not bdef.display_name.is_empty():
			display_name = bdef.display_name
	elif kind == &"unit":
		var udef: UnitDef = DataDB.get_unit_def(def_id)
		if udef != null and not udef.display_name.is_empty():
			display_name = udef.display_name

	var is_active: bool = bool(entity.get("has_move_target", false))
	if bool(entity.get("is_constructing", false)):
		is_active = true
	var status: String = "Idle"
	if is_active:
		status = "Active"
	return "%s\nStatus: %s\n(Production later)" % [display_name, status]
