extends Node2D

@onready var title_label: Label = $UILayer/HUD/TopBar/TitleLabel
@onready var tick_label: Label = $UILayer/HUD/TopBar/TickLabel
@onready var resources_label: Label = $UILayer/HUD/ResourcesLabel

var _last_second_mark: int = -1

func _ready() -> void:
	title_label.text = "Moon RTS"
	Sim.resources_changed.connect(_on_resources_changed)
	Game.start_new_match()
	_bootstrap_smoke_test_state()
	_on_resources_changed(Sim.resources)
	_update_tick_ui(true)

func _process(_delta: float) -> void:
	_update_tick_ui(false)

func _bootstrap_smoke_test_state() -> void:
	Sim.spawn_entity(&"command_dome", Vector2(320, 240), 1)
	Sim.spawn_entity(&"worker", Vector2(400, 280), 1)
	Sim.spawn_entity(&"soldier", Vector2(440, 320), 1)
	Sim.set_resource(&"regolith", 250)
	Sim.set_resource(&"metal", 125)
	Sim.set_resource(&"power", 80)
	Sim.set_resource(&"oxygen", 40)

func _on_resources_changed(new_resources: Dictionary) -> void:
	resources_label.text = "Resources | Regolith: %d  Metal: %d  Power: %d  Oxygen: %d" % [
		int(new_resources.get(&"regolith", 0)),
		int(new_resources.get(&"metal", 0)),
		int(new_resources.get(&"power", 0)),
		int(new_resources.get(&"oxygen", 0)),
	]

func _update_tick_ui(force: bool) -> void:
	var current_second := int(Sim.tick_count / Sim.TICKS_PER_SECOND)
	if force or current_second != _last_second_mark:
		_last_second_mark = current_second
		tick_label.text = "Tick: %d (%ds)" % [Sim.tick_count, current_second]
