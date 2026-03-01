extends Node2D

@onready var title_label: Label = $UILayer/HUD/TitleLabel
@onready var tick_label: Label = $UILayer/HUD/TickLabel
@onready var resources_label: Label = $UILayer/HUD/ResourcesLabel

func _ready() -> void:
	title_label.text = "Moon RTS"
	Sim.tick_advanced.connect(_on_tick_advanced)
	Sim.resources_changed.connect(_on_resources_changed)

	Game.start_new_match()
	_on_tick_advanced(Sim.tick_count)
	_on_resources_changed(Sim.resources)

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
