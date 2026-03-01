extends Node2D

const BUILD_STAMP: String = "dev-0002"

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
	print("Main scene: ", scene_path)
	print("Has Game autoload: ", str(Engine.has_singleton("Game")))
	print("Has Sim autoload: ", str(Engine.has_singleton("Sim")))
	print("Has CommandBus autoload: ", str(Engine.has_singleton("CommandBus")))
	print("Has DataDB autoload: ", str(Engine.has_singleton("DataDB")))
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
