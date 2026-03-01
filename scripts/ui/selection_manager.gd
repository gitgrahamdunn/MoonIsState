extends Node

const CLICK_RADIUS: float = 40.0

@export_node_path("Node2D") var world_path: NodePath

var selected_entity_ids: Array[int] = []

@onready var world: Node2D = get_node_or_null(world_path)

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
		if mb.button_index == MOUSE_BUTTON_LEFT:
			print("[Input] LEFT click @ ", mb.position)
			_handle_left_click(mb.position)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			print("[Input] RIGHT click @ ", mb.position)
			_handle_right_click()

func _unhandled_input(event: InputEvent) -> void:
	handle_unhandled_input(event)

func _handle_left_click(screen_pos: Vector2) -> void:
	var world_pos: Vector2 = _screen_to_world(screen_pos)
	print("SelectionManager left click at ", world_pos)
	var clicked_entity_id: int = _pick_single_entity(world_pos)
	if clicked_entity_id >= 0:
		selected_entity_ids = [clicked_entity_id]
	else:
		selected_entity_ids.clear()
	_apply_selection_visuals()

func _handle_right_click() -> void:
	if selected_entity_ids.is_empty():
		return
	var target_pos: Vector2 = _screen_to_world(get_viewport().get_mouse_position())
	print("SelectionManager right click at ", target_pos)
	var command: Dictionary = {
		"type": "move",
		"entity_ids": selected_entity_ids.duplicate(),
		"target_pos": target_pos,
	}
	CommandBus.enqueue(command)
	print("Enqueued move for ", selected_entity_ids, " to ", target_pos)

func _pick_single_entity(world_pos: Vector2) -> int:
	var closest_entity_id: int = -1
	var closest_distance: float = INF
	var unit_views: Array[Node] = _get_unit_views()
	for unit_view_node in unit_views:
		if not (unit_view_node is Node2D):
			continue
		if not unit_view_node.has_method("get_entity_id"):
			continue
		if not unit_view_node.has_method("get_world_pos"):
			continue
		var unit_world_pos: Vector2 = unit_view_node.call("get_world_pos") as Vector2
		var distance: float = unit_world_pos.distance_to(world_pos)
		if distance > CLICK_RADIUS:
			continue
		if distance < closest_distance:
			closest_distance = distance
			closest_entity_id = int(unit_view_node.call("get_entity_id"))
	return closest_entity_id

func _apply_selection_visuals() -> void:
	var unit_views: Array[Node] = _get_unit_views()
	for unit_view_node in unit_views:
		if not unit_view_node.has_method("get_entity_id"):
			continue
		if not unit_view_node.has_method("set_selected"):
			continue
		var entity_id: int = int(unit_view_node.call("get_entity_id"))
		unit_view_node.call("set_selected", selected_entity_ids.has(entity_id))

func _get_unit_views() -> Array[Node]:
	var nodes: Array[Node] = []
	for node_variant in get_tree().get_nodes_in_group("unit_views"):
		if node_variant is Node:
			nodes.append(node_variant)
	return nodes

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	if world != null:
		return world.get_canvas_transform().affine_inverse() * screen_pos
	var parent_node: Node = get_parent()
	if parent_node is Node2D:
		var parent_2d: Node2D = parent_node as Node2D
		return parent_2d.get_global_mouse_position()
	return screen_pos
