extends Node2D

const BUILD_STAMP: String = "dev-0013"

@onready var title_label: Label = $UILayer/HUD/TitleLabel
@onready var tick_label: Label = $UILayer/HUD/TickLabel
@onready var resources_label: Label = $UILayer/HUD/ResourcesLabel
@onready var selection_manager: Node = get_node_or_null("SelectionManager")
@onready var launch_console: Control = $UILayer/HUD/LaunchConsole

func _ready() -> void:
	var hud_node: Control = get_node_or_null("UILayer/HUD") as Control
	if hud_node != null:
		hud_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child_node: Node in hud_node.get_children():
			if child_node is Control and child_node.name != "LaunchConsole":
				var child_control: Control = child_node as Control
				child_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	title_label.text = "MoonIsState  [" + BUILD_STAMP + "]"
	Sim.tick_advanced.connect(_on_tick_advanced)
	Sim.resources_changed.connect(_on_resources_changed)

	Game.start_new_match()
	log_startup_smoke_check()
	_on_tick_advanced(Sim.tick_count)
	_on_resources_changed(Sim.resources)

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
	resources_label.text = "Regolith: %.1f\nMetal: %.1f\nPower: %.1f\nOxygen: %.1f" % [
		float(new_resources.get(&"regolith", 0.0)),
		float(new_resources.get(&"metal", 0.0)),
		float(new_resources.get(&"power", 0.0)),
		float(new_resources.get(&"oxygen", 0.0)),
	]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
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
	return get_global_mouse_position()
