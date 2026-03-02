extends Node

var current_match_id: String = ""

func start_new_match() -> void:
	DataDB.load_all()
	if DataDB.units.size() == 0 and DataDB.buildings.size() == 0 and DataDB.tech.size() == 0:
		push_error("DataDB is empty; check res://data/*.tres are present and loader works.")
		return

	Sim.reset()
	current_match_id = "new_match"

	Sim.set_resource(&"regolith", 0.0)
	Sim.set_resource(&"metal", 40.0)
	Sim.set_resource(&"power", 0.0)
	Sim.set_resource(&"oxygen", 0.0)

	var command_dome_id: int = Sim.spawn_entity(&"command_dome", Vector2(200, 200), 1, &"building")
	var worker_a_id: int = Sim.spawn_entity(&"worker", Vector2(320, 240), 1, &"unit")
	var worker_b_id: int = Sim.spawn_entity(&"worker", Vector2(350, 260), 1, &"unit")
	var worker_c_id: int = Sim.spawn_entity(&"worker", Vector2(350, 220), 1, &"unit")
	_verify_spawn_kinds(command_dome_id, [worker_a_id, worker_b_id, worker_c_id])

func load_match(path: String) -> void:
	push_warning("load_match is not implemented yet: %s" % path)

func save_match(path: String) -> void:
	push_warning("save_match is not implemented yet: %s" % path)

func _verify_spawn_kinds(command_dome_id: int, worker_ids: Array[int]) -> void:
	var command_dome: Dictionary = Sim.get_entity(command_dome_id)
	var command_dome_kind: StringName = command_dome.get("kind", &"") as StringName
	var command_dome_def_id: StringName = command_dome.get("def_id", &"") as StringName
	if command_dome_kind != &"building":
		push_error("command_dome must spawn as kind=building")
	if command_dome_def_id != &"command_dome":
		push_error("command_dome must spawn with def_id=command_dome")
	for worker_id: int in worker_ids:
		var worker: Dictionary = Sim.get_entity(worker_id)
		var worker_kind: StringName = worker.get("kind", &"") as StringName
		var worker_def_id: StringName = worker.get("def_id", &"") as StringName
		if worker_kind != &"unit":
			push_error("worker must spawn as kind=unit")
		if worker_def_id != &"worker":
			push_error("worker must spawn with def_id=worker")
