extends Node

var current_match_id: String = ""

func start_new_match() -> void:
	Sim.reset()
	DataDB.load_all()
	current_match_id = "new_match"

	Sim.set_resource(&"regolith", 250)
	Sim.set_resource(&"metal", 125)
	Sim.set_resource(&"power", 80)
	Sim.set_resource(&"oxygen", 40)

	Sim.spawn_entity(&"command_dome", Vector2(200, 200), 1)
	Sim.spawn_entity(&"worker", Vector2(320, 240), 1)

func load_match(path: String) -> void:
	push_warning("load_match is not implemented yet: %s" % path)

func save_match(path: String) -> void:
	push_warning("save_match is not implemented yet: %s" % path)
