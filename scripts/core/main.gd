extends Node2D

const BUILD_STAMP: String = "dev-0011"
const PAN_SPEED: float = 320.0
const CAMERA_ZOOM_LEVELS: Array[float] = [1.0, 2.0, 3.0]

@onready var title_label: Label = $UILayer/HUD/TitleLabel
@onready var tick_label: Label = $UILayer/HUD/TickLabel
@onready var resources_label: Label = $UILayer/HUD/ResourcesLabel
@onready var selection_manager: Node = get_node_or_null("SelectionManager")
@onready var launch_console: Control = $UILayer/HUD/LaunchConsole
@onready var world_viewport_container: SubViewportContainer = $WorldViewportContainer
@onready var world_viewport: SubViewport = $WorldViewportContainer/WorldViewport
@onready var world_camera: Camera2D = $WorldViewportContainer/WorldViewport/World/Camera2D

var _zoom_index: int = 0

func _ready() -> void:
	var hud_node: Control = get_node_or_null("UILayer/HUD") as Control
	if hud_node != null:
		hud_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child_node: Node in hud_node.get_children():
			if child_node is Control and child_node.name != "LaunchConsole":
				var child_control: Control = child_node as Control
				child_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	RenderingServer.viewport_set_snap_2d_transforms_to_pixel(world_viewport.get_viewport_rid(), true)
	RenderingServer.viewport_set_snap_2d_vertices_to_pixel(world_viewport.get_viewport_rid(), true)
	_apply_camera_zoom()

	title_label.text = "MoonIsState  [" + BUILD_STAMP + "]"
	Sim.tick_advanced.connect(_on_tick_advanced)
	Sim.resources_changed.connect(_on_resources_changed)

	Game.start_new_match()
	log_startup_smoke_check()
	_on_tick_advanced(Sim.tick_count)
	_on_resources_changed(Sim.resources)

func _process(delta: float) -> void:
	var input_vec: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vec == Vector2.ZERO:
		return
	world_camera.position += input_vec.normalized() * PAN_SPEED * delta * world_camera.zoom.x

func log_startup_smoke_check() -> void:
	print("=== Moon RTS Smoke Check ===")
	print("Godot version: ", Engine.get_version_info())
	print("Project path: ", ProjectSettings.globalize_path("res://"))
	var scene_path: String = "<no current scene>"
	if get_tree().current_scene != null:
		scene_path = String(get_tree().current_scene.scene_file_path)
	var has_game: bool = get_node_or_null("/root/Game") != null
	var has_sim: bool = get_node_or_null("/root/Sim") != null
	var has_command_bus: bool = get_node_or_null("/root/CommandBus") != null
	var has_data_db: bool = get_node_or_null("/root/DataDB") != null
	print("Main scene: ", scene_path)
	print("Has Game autoload: ", str(has_game))
	print("Has Sim autoload: ", str(has_sim))
	print("Has CommandBus autoload: ", str(has_command_bus))
	print("Has DataDB autoload: ", str(has_data_db))
	print("DataDB unit defs loaded: ", DataDB.units.size())
	print("DataDB building defs loaded: ", DataDB.buildings.size())
	print("DataDB tech defs loaded: ", DataDB.tech.size())
	print("Sim ticks per second: ", Sim.TICKS_PER_SECOND)
	print("Initial entity count after match start: ", Sim.entities.size())

func _on_tick_advanced(new_tick_count: int) -> void:
	var seconds: float = float(new_tick_count) / float(Sim.TICKS_PER_SECOND)
	tick_label.text = "Tick: %d (%.1fs)" % [new_tick_count, seconds]

func _on_resources_changed(new_resources: Dictionary) -> void:
	resources_label.text = "Regolith: %.1f\nMetal: %.1f\nPower: %.1f\nOxygen: %.1f\nScrap: %.1f" % [
		float(new_resources.get(&"regolith", 0.0)),
		float(new_resources.get(&"metal", 0.0)),
		float(new_resources.get(&"power", 0.0)),
		float(new_resources.get(&"oxygen", 0.0)),
		float(new_resources.get(&"scrap", 0.0)),
	]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_index = maxi(_zoom_index - 1, 0)
			_apply_camera_zoom()
			get_viewport().set_input_as_handled()
			return
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_index = mini(_zoom_index + 1, CAMERA_ZOOM_LEVELS.size() - 1)
			_apply_camera_zoom()
			get_viewport().set_input_as_handled()
			return
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and launch_console != null:
			if launch_console.has_method("wants_build_placement") and launch_console.call("wants_build_placement") as bool:
				var world_pos: Vector2 = get_world_mouse_pos()
				var selected_ids: Array[int] = []
				if selection_manager != null:
					selected_ids = selection_manager.get("selected_entity_ids") as Array[int]
				var consumed: bool = launch_console.call("try_handle_left_click", world_pos, selected_ids) as bool
				if consumed:
					get_viewport().set_input_as_handled()
					return

	if selection_manager != null and selection_manager.has_method("handle_unhandled_input"):
		selection_manager.call("handle_unhandled_input", event)

func get_world_mouse_pos() -> Vector2:
	var mouse_screen_pos: Vector2 = get_viewport().get_mouse_position()
	var container_screen_pos: Vector2 = world_viewport_container.global_position
	var container_size: Vector2 = world_viewport_container.size
	if container_size.x <= 0.0 or container_size.y <= 0.0:
		return world_camera.global_position
	var local_pos: Vector2 = mouse_screen_pos - container_screen_pos
	var clamped: Vector2 = Vector2(
		clampf(local_pos.x, 0.0, container_size.x),
		clampf(local_pos.y, 0.0, container_size.y)
	)
	var scale_ratio: Vector2 = Vector2(
		float(world_viewport.size.x) / container_size.x,
		float(world_viewport.size.y) / container_size.y
	)
	var viewport_pos: Vector2 = clamped * scale_ratio
	var world_pos: Vector2 = ((viewport_pos - (Vector2(world_viewport.size) * 0.5)) / world_camera.zoom) + world_camera.global_position
	return world_pos

func _apply_camera_zoom() -> void:
	var zoom_value: float = CAMERA_ZOOM_LEVELS[_zoom_index]
	world_camera.zoom = Vector2(zoom_value, zoom_value)
