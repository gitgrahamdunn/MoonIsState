extends PanelContainer

@onready var money_label: Label = $VBox/MoneyLabel
@onready var revenue_label: Label = $VBox/RevenueLabel
@onready var metal_label: Label = $VBox/MetalLabel
@onready var clankers_label: Label = $VBox/ClankersLabel
@onready var build_button: Button = $VBox/BuildLaunchpadButton
@onready var launch_robot_button: Button = $VBox/LaunchRobotButton
@onready var launch_earth_button: Button = $VBox/LaunchEarthButton
@onready var scrap_button: Button = $VBox/ScrapBrokenButton

var _build_mode: bool = false
var _builder_id: int = -1
var _refresh_timer: float = 0.0

func _ready() -> void:
	build_button.pressed.connect(_on_build_launchpad_pressed)
	launch_robot_button.pressed.connect(_on_launch_robot_pressed)
	launch_earth_button.pressed.connect(_on_launch_earth_pressed)
	scrap_button.pressed.connect(_on_scrap_broken_pressed)
	Sim.resources_changed.connect(_on_resources_changed)
	_update_ui()

func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 0.2:
		_refresh_timer = 0.0
		_update_ui()

func wants_build_placement() -> bool:
	return _build_mode

func try_handle_left_click(world_pos: Vector2, selected_ids: Array[int]) -> bool:
	if not _build_mode:
		return false
	if _builder_id <= 0:
		if selected_ids.size() <= 0:
			print("[BuildUI] No clanker selected")
			_build_mode = false
			_update_ui()
			return false
		_builder_id = int(selected_ids[0])
	CommandBus.enqueue({
		"type": "build",
		"builder_id": _builder_id,
		"building_def": &"launchpad",
		"pos": world_pos,
	})
	_build_mode = false
	_builder_id = -1
	_update_ui()
	return true

func _on_build_launchpad_pressed() -> void:
	var manager: Node = get_tree().get_first_node_in_group("selection_manager")
	if manager == null:
		return
	var selected_ids: Array[int] = manager.get("selected_entity_ids") as Array[int]
	if selected_ids.size() <= 0:
		print("[BuildUI] Select a clanker first")
		return
	_builder_id = int(selected_ids[0])
	_build_mode = true
	_update_ui()

func _on_launch_robot_pressed() -> void:
	CommandBus.enqueue({"type": "launch_robot"})

func _on_launch_earth_pressed() -> void:
	CommandBus.enqueue({"type": "launch_earth_mission"})

func _on_scrap_broken_pressed() -> void:
	var manager: Node = get_tree().get_first_node_in_group("selection_manager")
	if manager == null:
		return
	var selected_ids: Array[int] = manager.get("selected_entity_ids") as Array[int]
	if selected_ids.is_empty():
		return
	var selected_id: int = int(selected_ids[0])
	var entity: Dictionary = Sim.get_entity(selected_id)
	if entity.is_empty():
		return
	if (entity.get("kind", &"") as StringName) != &"unit":
		return
	if not bool(entity.get("is_broken", false)):
		return
	CommandBus.enqueue({
		"type": "scrap_broken",
		"broken_id": selected_id,
	})

func _on_resources_changed(_new_resources: Dictionary) -> void:
	_update_ui()

func _update_ui() -> void:
	var money: float = Sim.get_resource(&"money")
	var metal: float = Sim.get_resource(&"metal")
	var has_launchpad: bool = Sim.has_completed_launchpad()
	var revenue_min: float = Sim.money_rate_per_sec * 60.0

	money_label.text = "Money: %.2f B$" % money
	revenue_label.text = "Revenue: +%.3f B$/min" % revenue_min
	metal_label.text = "Metal: %.1f" % metal

	var total_clankers: int = 0
	var broken_clankers: int = 0
	var active_builds: int = 0
	var assigned_builders: int = 0
	for idv: Variant in Sim.entities.keys():
		var entity_id: int = int(idv)
		var e: Dictionary = Sim.entities[entity_id] as Dictionary
		var kind: StringName = e.get("kind", &"") as StringName
		if kind == &"unit":
			total_clankers += 1
			if bool(e.get("is_broken", false)):
				broken_clankers += 1
		elif kind == &"building":
			if bool(e.get("is_constructing", false)):
				active_builds += 1
				var assigned: Array[int] = e.get("assigned_clankers", []) as Array[int]
				assigned_builders += assigned.size()
	clankers_label.text = "Clankers: %d/%d broken | Active builds: %d | Throughput: %d" % [broken_clankers, total_clankers, active_builds, assigned_builders]

	build_button.text = "Build Launchpad"
	if _build_mode:
		build_button.text = "Place Launchpad..."

	var selected_broken_id: int = _get_selected_broken_clanker_id()
	scrap_button.disabled = selected_broken_id <= 0
	launch_robot_button.disabled = (not has_launchpad) or money < 1.0
	launch_earth_button.disabled = (not has_launchpad) or money < 2.0

func _get_selected_broken_clanker_id() -> int:
	var manager: Node = get_tree().get_first_node_in_group("selection_manager")
	if manager == null:
		return -1
	var selected_ids: Array[int] = manager.get("selected_entity_ids") as Array[int]
	if selected_ids.is_empty():
		return -1
	var selected_id: int = int(selected_ids[0])
	var selected_entity: Dictionary = Sim.get_entity(selected_id)
	if selected_entity.is_empty():
		return -1
	var selected_kind: StringName = selected_entity.get("kind", &"") as StringName
	if selected_kind != &"unit":
		return -1
	var is_broken: bool = bool(selected_entity.get("is_broken", false))
	if not is_broken:
		return -1
	return selected_id
