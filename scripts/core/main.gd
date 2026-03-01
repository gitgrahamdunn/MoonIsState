extends Node2D

const BUILD_STAMP: String = "dev-0004"

@onready var title_label: Label = $UILayer/HUD/TitleLabel
@onready var tick_label: Label = $UILayer/HUD/TickLabel
@onready var resources_label: Label = $UILayer/HUD/ResourcesLabel

func _ready() -> void:
	title_label.text = "Moon RTS  [" + BUILD_STAMP + "]"
	Sim.tick_advanced.connect(_on_tick_advanced)
	Sim.resources_changed.connect(_on_resources_changed)

	Game.start_new_match()
	log_startup_smoke_check()
	_on_tick_advanced(Sim.tick_count)
	_on_resources_changed(Sim.resources)

func log_startup_smoke_check() -> void:
	print("=== Moon RTS Smoke Check ===")
	print("Godot version: ", Engine.get_version_info())
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
	var seconds := float(new_tick_count) / float(Sim.TICKS_PER_SECOND)
	tick_label.text = "Tick: %d (%.1fs)" % [new_tick_count, seconds]

func _on_resources_changed(new_resources: Dictionary) -> void:
	resources_label.text = "Regolith: %d\nMetal: %d\nPower: %d\nOxygen: %d" % [
		int(new_resources.get(&"regolith", 0)),
		int(new_resources.get(&"metal", 0)),
		int(new_resources.get(&"power", 0)),
		int(new_resources.get(&"oxygen", 0)),
	]
