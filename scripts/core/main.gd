extends Node2D

const BUILD_STAMP: String = "dev-0023-first-landing-min"
const PAN_SPEED: float = 320.0
const CAMERA_ZOOM_LEVELS: Array[float] = [1.0, 2.0, 3.0]

@onready var hud: Control = get_node_or_null("UILayer/HUD") as Control
@onready var selection_manager: Node = get_node_or_null("SelectionManager")
@onready var world_camera: Camera2D = get_node_or_null("World/WorldCamera") as Camera2D
@onready var hover_manager: Node = get_node_or_null("HoverManager")

var _zoom_index: int = 0

func _ready() -> void:
	_apply_camera_zoom()

	Game.start_new_match()
	_center_camera_on_lander()
	_reset_zoom()
	log_startup_smoke_check()
	run_smoke_checks()
	await get_tree().process_frame
	if hud != null and hud.has_method("set_build_stamp"):
		hud.call("set_build_stamp", BUILD_STAMP)
	if hover_manager != null and hover_manager.has_method("set_context"):
		hover_manager.call("set_context", self, hud)

func _process(delta: float) -> void:
	var input_vec: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vec == Vector2.ZERO:
		return
	world_camera.position += input_vec.normalized() * PAN_SPEED * delta * world_camera.zoom.x

func log_startup_smoke_check() -> void:
	print("=== Moon RTS Smoke Check ===")
	var version_info: Dictionary = Engine.get_version_info()
	var version_string: String = version_info.get("string", "<unknown>") as String
	print("Godot version info: ", version_info)
	print("Godot version string: ", version_string)
	print("Project path: ", ProjectSettings.globalize_path("res://"))

	var default_texture_filter: Variant = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
	var snap_transforms: Variant = ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel")
	var snap_vertices: Variant = ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel")
	print("Default texture filter: ", default_texture_filter)
	print("Snap transforms to pixel: ", snap_transforms)
	print("Snap vertices to pixel: ", snap_vertices)
	print("Window size: ", get_window().size)

	if RenderingServer.has_method("get_video_adapter_name"):
		print("Renderer adapter: ", RenderingServer.call("get_video_adapter_name"))
		if RenderingServer.has_method("get_video_adapter_vendor"):
			print("Renderer vendor: ", RenderingServer.call("get_video_adapter_vendor"))
		if RenderingServer.has_method("get_video_adapter_api_version"):
			print("Renderer API version: ", RenderingServer.call("get_video_adapter_api_version"))
	else:
		print("Renderer adapter info unavailable via RenderingServer methods; see engine startup logs.")

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

func run_smoke_checks() -> void:
	var has_fail: bool = false
	if get_node_or_null("/root/Sim") == null:
		push_error("SMOKE FAIL: /root/Sim missing")
		has_fail = true
	if get_node_or_null("/root/DataDB") == null:
		push_error("SMOKE FAIL: /root/DataDB missing")
		has_fail = true
	if DataDB.buildings.size() < 4:
		push_error("SMOKE FAIL: DataDB.buildings.size() < 4")
		has_fail = true
	if Sim.entities.size() <= 0:
		push_error("SMOKE FAIL: Sim.entities.size() <= 0")
		has_fail = true
	if get_node_or_null("UILayer/HUD/ObjectivesPanel") == null:
		push_error("SMOKE FAIL: ObjectivesPanel missing at UILayer/HUD/ObjectivesPanel")
		has_fail = true
	if get_node_or_null("ObjectivesController") == null:
		push_error("SMOKE FAIL: ObjectivesController missing")
		has_fail = true
	if get_node_or_null("World/WorldSpawner") == null:
		push_error("SMOKE FAIL: WorldSpawner missing")
		has_fail = true
	if not has_fail:
		print("=== SMOKE OK ===")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_C:
			_center_camera_on_lander()
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_HOME:
			_reset_zoom()
			get_viewport().set_input_as_handled()
			return

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

	if selection_manager != null and selection_manager.has_method("handle_unhandled_input"):
		selection_manager.call("handle_unhandled_input", event)

func get_world_mouse_pos() -> Vector2:
	return get_global_mouse_position()

func _apply_camera_zoom() -> void:
	var zoom_value: float = CAMERA_ZOOM_LEVELS[_zoom_index]
	world_camera.zoom = Vector2(zoom_value, zoom_value)

func _center_camera_on_lander() -> void:
	if world_camera == null:
		push_warning("[Camera] WorldCamera not found; cannot center.")
		return

	var focus_pos: Vector2 = Vector2.ZERO
	var found: bool = false

	for idv: Variant in Sim.entities.keys():
		var id: int = int(idv)
		var e: Dictionary = Sim.entities[id] as Dictionary
		var def_id: StringName = e.get("def_id", &"") as StringName
		var pos: Vector2 = e.get("pos", Vector2.ZERO) as Vector2
		if def_id == &"hls_lander":
			focus_pos = pos
			found = true
			break

	if not found:
		for idv: Variant in Sim.entities.keys():
			var id2: int = int(idv)
			var e2: Dictionary = Sim.entities[id2] as Dictionary
			var def_id2: StringName = e2.get("def_id", &"") as StringName
			var pos2: Vector2 = e2.get("pos", Vector2.ZERO) as Vector2
			if def_id2 == &"command_dome":
				focus_pos = pos2
				found = true
				break

	if not found and Sim.entities.size() > 0:
		var first_id: int = int(Sim.entities.keys()[0])
		var e3: Dictionary = Sim.entities[first_id] as Dictionary
		focus_pos = e3.get("pos", Vector2.ZERO) as Vector2

	world_camera.global_position = focus_pos
	print("[Camera] Centered on ", focus_pos)

func _reset_zoom() -> void:
	_zoom_index = 0
	_apply_camera_zoom()
