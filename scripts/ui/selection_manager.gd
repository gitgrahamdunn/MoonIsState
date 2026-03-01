extends Node

const CLICK_RADIUS := 16.0
const DRAG_THRESHOLD := 8.0

@export_node_path("Control") var overlay_path: NodePath
@export_node_path("Node2D") var world_path: NodePath

var selected_entity_ids: Array[int] = []
var _drag_start_screen: Vector2 = Vector2.ZERO
var _drag_end_screen: Vector2 = Vector2.ZERO
var _is_dragging: bool = false

@onready var overlay: Control = get_node_or_null(overlay_path)
@onready var world: Node2D = get_node_or_null(world_path)

func _ready() -> void:
	add_to_group("selection_manager")

func _exit_tree() -> void:
	remove_from_group("selection_manager")

func is_selected(entity_id: int) -> bool:
	return selected_entity_ids.has(entity_id)

func is_entity_selected(entity_id: int) -> bool:
	return is_selected(entity_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _is_dragging:
		_drag_end_screen = event.position
		if overlay != null and overlay.has_method("set_drag_rect"):
			overlay.call("set_drag_rect", _drag_start_screen, _drag_end_screen)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start_screen = event.position
			_drag_end_screen = event.position
			_is_dragging = true
			if overlay != null and overlay.has_method("set_drag_rect"):
				overlay.call("set_drag_rect", _drag_start_screen, _drag_end_screen)
		else:
			if not _is_dragging:
				return
			_drag_end_screen = event.position
			_is_dragging = false
			if overlay != null and overlay.has_method("clear_drag_rect"):
				overlay.call("clear_drag_rect")
			_apply_selection_from_drag(event.shift_pressed)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		issue_move_command()

func _apply_selection_from_drag(append_selection: bool) -> void:
	var drag_distance := _drag_start_screen.distance_to(_drag_end_screen)
	var next_selection: Array[int] = []
	if append_selection:
		next_selection = selected_entity_ids.duplicate()

	if drag_distance <= DRAG_THRESHOLD:
		var clicked := _pick_single_entity(_drag_end_screen)
		if clicked >= 0:
			if not next_selection.has(clicked):
				next_selection.append(clicked)
		elif not append_selection:
			next_selection.clear()
		selected_entity_ids = next_selection
		return

	var selection_rect := Rect2(_drag_start_screen, _drag_end_screen - _drag_start_screen).abs()
	for unit_view in _get_unit_views():
		var screen_pos := get_viewport().get_canvas_transform() * unit_view.global_position
		if selection_rect.has_point(screen_pos) and not next_selection.has(unit_view.entity_id):
			next_selection.append(unit_view.entity_id)
	selected_entity_ids = next_selection

func _pick_single_entity(screen_pos: Vector2) -> int:
	var closest_entity_id := -1
	var closest_distance := INF
	for unit_view in _get_unit_views():
		var unit_screen_pos := get_viewport().get_canvas_transform() * unit_view.global_position
		var distance := unit_screen_pos.distance_to(screen_pos)
		if distance > CLICK_RADIUS:
			continue
		if distance < closest_distance:
			closest_distance = distance
			closest_entity_id = unit_view.entity_id
	return closest_entity_id

func issue_move_command() -> void:
	if selected_entity_ids.is_empty():
		return
	if world == null:
		return
	var world_mouse_pos := world.get_global_mouse_position()
	CommandBus.enqueue({
		"type": "move",
		"entity_ids": selected_entity_ids.duplicate(),
		"target_pos": world_mouse_pos,
	})

func _get_unit_views() -> Array:
	return get_tree().get_nodes_in_group("unit_views")
