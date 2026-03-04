extends Node

var current_match_id: String = ""

func start_new_match() -> void:
	DataDB.load_all()
	if DataDB.units.size() == 0 and DataDB.buildings.size() == 0 and DataDB.tech.size() == 0:
		push_error("DataDB is empty; check res://data/*.tres are present and loader works.")
		return

	Sim.reset()
	current_match_id = "new_match"

	Sim.set_resource(&"credits", 2000.0)
	Sim.set_resource(&"regolith", 80.0)
	Sim.set_resource(&"metal", 30.0)
	Sim.set_resource(&"power", 30.0)
	Sim.set_resource(&"oxygen", 30.0)

	var lander_pos: Vector2 = Vector2(240.0, 180.0)
	var lander_id: int = Sim.spawn_entity(&"hls_lander", lander_pos, 1, &"building")
	var command_dome_id: int = Sim.spawn_entity(&"command_dome", lander_pos + Vector2(90.0, 40.0), 1, &"building")
	Sim.spawn_entity(&"scrap_heap", lander_pos + Vector2(120.0, 20.0), 1, &"building")
	var worker_a_id: int = Sim.spawn_entity(&"worker", lander_pos + Vector2(-30.0, 70.0), 1, &"unit")
	var worker_b_id: int = Sim.spawn_entity(&"worker", lander_pos + Vector2(30.0, 70.0), 1, &"unit")
	Sim.spawn_entity(&"starter_crate", lander_pos + Vector2(-70.0, -30.0), 1, &"building")
	Sim.spawn_entity(&"starter_crate", lander_pos + Vector2(-40.0, -50.0), 1, &"building")
	Sim.spawn_entity(&"starter_crate", lander_pos + Vector2(-10.0, -40.0), 1, &"building")
	_verify_spawn_kinds(lander_id, command_dome_id, [worker_a_id, worker_b_id])
	print("[Game] spawned entities: ", Sim.entities.size())

	var fx_pos: Vector2 = lander_pos
	var lander: Dictionary = Sim.get_entity(lander_id)
	if not lander.is_empty():
		fx_pos = lander.get("pos", fx_pos) as Vector2
	else:
		var command_dome: Dictionary = Sim.get_entity(command_dome_id)
		if not command_dome.is_empty():
			fx_pos = command_dome.get("pos", fx_pos) as Vector2
	Sim.emit_signal("fx_popup", fx_pos, "First landing successful!", &"info")
	Sim.emit_signal("fx_burst", fx_pos, &"sparkle")

func load_match(path: String) -> void:
	push_warning("load_match is not implemented yet: %s" % path)

func save_match(path: String) -> void:
	push_warning("save_match is not implemented yet: %s" % path)

func _verify_spawn_kinds(lander_id: int, command_dome_id: int, clanker_ids: Array[int]) -> void:
	var lander: Dictionary = Sim.get_entity(lander_id)
	var lander_kind: StringName = lander.get("kind", &"") as StringName
	var lander_def_id: StringName = lander.get("def_id", &"") as StringName
	if lander_kind != &"building":
		push_error("hls_lander must spawn as kind=building")
	if lander_def_id != &"hls_lander":
		push_error("hls_lander must spawn with def_id=hls_lander")

	var command_dome: Dictionary = Sim.get_entity(command_dome_id)
	var command_dome_kind: StringName = command_dome.get("kind", &"") as StringName
	var command_dome_def_id: StringName = command_dome.get("def_id", &"") as StringName
	if command_dome_kind != &"building":
		push_error("command_dome must spawn as kind=building")
	if command_dome_def_id != &"command_dome":
		push_error("command_dome must spawn with def_id=command_dome")
	for clanker_id: int in clanker_ids:
		var clanker: Dictionary = Sim.get_entity(clanker_id)
		var clanker_kind: StringName = clanker.get("kind", &"") as StringName
		var clanker_def_id: StringName = clanker.get("def_id", &"") as StringName
		if clanker_kind != &"unit":
			push_error("clanker must spawn as kind=unit")
		if clanker_def_id != &"worker":
			push_error("clanker must spawn with def_id=worker")
