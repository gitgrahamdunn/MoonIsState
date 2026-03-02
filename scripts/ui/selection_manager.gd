extends Node

const CLICK_RADIUS: float = 40.0
const DEBUG_INPUT: bool = true

var selected_entity_ids: Array[int] = []

func _ready() -> void:
	add_to_group("selection_manager")

func _exit_tree() -> void:
	remove_from_group("selection_manager")

func is_selected(entity_id: int) -> bool:
	return selected_entity_ids.has(entity_id)

func is_entity_selected(entity_id: int) -> bool:
	return is_selected(entity_id)

func handle_unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		var main: Node = get_tree().current_scene
		if main == null or not main.has_method("get_world_mouse_pos"):
			return
		var world_pos: Vector2 = main.call("get_world_mouse_pos") as Vector2
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if DEBUG_INPUT:
				print("[Input] LEFT click @ ", mb.position)
			_try_select_at(world_pos)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if DEBUG_INPUT:
				print("[Input] RIGHT click @ ", mb.position)
			if selected_entity_ids.size() > 0:
				var target: Vector2 = world_pos
				CommandBus.enqueue({
					"type": "move",
					"entity_ids": selected_entity_ids.duplicate(),
					"target_pos": target,
				})
				if DEBUG_INPUT:
					print("[Cmd] move enqueue ids=", selected_entity_ids, " target=", target)

func _unhandled_input(event: InputEvent) -> void:
	handle_unhandled_input(event)

func _select_single(entity_id: int) -> void:
	selected_entity_ids = [entity_id]
	_apply_selection_to_views()
	if DEBUG_INPUT:
		print("[Select] selected: ", selected_entity_ids)

func _clear_selection() -> void:
	selected_entity_ids.clear()
	_apply_selection_to_views()
	if DEBUG_INPUT:
		print("[Select] cleared")

func _apply_selection_to_views() -> void:
	var views: Array = get_tree().get_nodes_in_group("unit_views")
	for v in views:
		if v != null and v.has_method("get_entity_id") and v.has_method("set_selected"):
			var vid: int = int(v.call("get_entity_id"))
			v.call("set_selected", selected_entity_ids.has(vid))

func _try_select_at(world_pos: Vector2) -> void:
	var views: Array = get_tree().get_nodes_in_group("unit_views")
	var best_id: int = -1
	var best_d2: float = 1e18
	for v in views:
		if v == null or not v.has_method("get_world_pos") or not v.has_method("get_entity_id"):
			continue
		var vp: Vector2 = v.call("get_world_pos") as Vector2
		var d2: float = vp.distance_squared_to(world_pos)
		if d2 < best_d2:
			best_d2 = d2
			best_id = int(v.call("get_entity_id"))
	if best_id != -1 and best_d2 <= CLICK_RADIUS * CLICK_RADIUS:
		_select_single(best_id)
	else:
		_clear_selection()
