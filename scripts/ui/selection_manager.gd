extends Control

const CLICK_RADIUS := 16.0
const DRAG_THRESHOLD := 8.0

var selected_entity_ids: Array[int] = []
var _drag_start_screen: Vector2 = Vector2.ZERO
var _drag_end_screen: Vector2 = Vector2.ZERO
var _is_dragging: bool = false

func _ready() -> void:
	add_to_group("selection_manager")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _exit_tree() -> void:
	remove_from_group("selection_manager")

func get_selected_entity_ids() -> Array[int]:
	return selected_entity_ids.duplicate()

func is_entity_selected(entity_id: int) -> bool:
	return selected_entity_ids.has(entity_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _is_dragging:
		_drag_end_screen = event.position
		queue_redraw()

func _draw() -> void:
	if not _is_dragging:
		return
	var rect := Rect2(_drag_start_screen, _drag_end_screen - _drag_start_screen).abs()
	draw_rect(rect, Color(0.3, 0.8, 1.0, 0.15), true)
	draw_rect(rect, Color(0.3, 0.8, 1.0, 0.9), false, 2.0)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start_screen = event.position
			_drag_end_screen = event.position
			_is_dragging = true
			queue_redraw()
		else:
			if not _is_dragging:
				return
			_drag_end_screen = event.position
			_is_dragging = false
			_apply_selection_from_drag(event.shift_pressed)
			queue_redraw()
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_issue_move_command(event.position)

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
		else:
			if not append_selection:
				next_selection.clear()
		selected_entity_ids = next_selection
		return

	var selection_rect := Rect2(_drag_start_screen, _drag_end_screen - _drag_start_screen).abs()
	for unit_view in _get_unit_views():
		var screen_pos := get_viewport().get_canvas_transform() * unit_view.global_position
		if selection_rect.has_point(screen_pos):
			if not next_selection.has(unit_view.entity_id):
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

func _issue_move_command(screen_pos: Vector2) -> void:
	if selected_entity_ids.is_empty():
		return
	var world_pos := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	CommandBus.enqueue({
		"type": "move",
		"entity_ids": selected_entity_ids.duplicate(),
		"target_pos": world_pos,
	})

func _get_unit_views() -> Array:
	return get_tree().get_nodes_in_group("unit_views")
