extends Node

var current_match_id: String = ""

func start_new_match() -> void:
	DataDB.load_all()
	if DataDB.units.size() == 0 and DataDB.buildings.size() == 0 and DataDB.tech.size() == 0:
		push_error("DataDB is empty; check res://data/*.tres are present and loader works.")
		return

	Sim.reset()
	current_match_id = "new_match"

	Sim.set_resource(&"money", 2000.0)
	Sim.set_resource(&"regolith", 80.0)
	Sim.set_resource(&"metal", 30.0)
	Sim.set_resource(&"power", 30.0)
	Sim.set_resource(&"oxygen", 30.0)

	var start_pos: Vector2 = Vector2(240.0, 180.0)
	var lander_id: int = Sim.spawn_entity(&"hls_lander", start_pos, 1, &"building")
	var command_dome_id: int = Sim.spawn_entity(&"command_dome", start_pos + Vector2(72.0, 24.0), 1, &"building")
	var clanker_a_id: int = Sim.spawn_entity(&"worker", start_pos + Vector2(54.0, 76.0), 1, &"unit")
	var clanker_b_id: int = Sim.spawn_entity(&"worker", start_pos + Vector2(-48.0, 62.0), 1, &"unit")
	var supply_crate_a_id: int = Sim.spawn_entity(&"scrap_heap", start_pos + Vector2(128.0, 40.0), 1, &"building")
	var supply_crate_b_id: int = Sim.spawn_entity(&"scrap_heap", start_pos + Vector2(-112.0, 16.0), 1, &"building")
	print("[Game] Sim.entities.size=", Sim.entities.size())
	_verify_spawn_kinds(lander_id, command_dome_id, [clanker_a_id, clanker_b_id], [supply_crate_a_id, supply_crate_b_id])
	_log_start_state_smoke_check()

func load_match(path: String) -> void:
	push_warning("load_match is not implemented yet: %s" % path)

func save_match(path: String) -> void:
	push_warning("save_match is not implemented yet: %s" % path)

func _verify_spawn_kinds(lander_id: int, command_dome_id: int, clanker_ids: Array[int], supply_ids: Array[int]) -> void:
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

	for supply_id: int in supply_ids:
		var supply_entity: Dictionary = Sim.get_entity(supply_id)
		var supply_kind: StringName = supply_entity.get("kind", &"") as StringName
		var supply_def_id: StringName = supply_entity.get("def_id", &"") as StringName
		if supply_kind != &"building":
			push_error("starter supply crate must spawn as kind=building")
		if supply_def_id != &"scrap_heap":
			push_error("starter supply crate must spawn with def_id=scrap_heap")

func _log_start_state_smoke_check() -> void:
	print("=== FIRST LANDING START STATE SMOKE ===")
	var has_solar_def: bool = DataDB.get_building_def(&"solar_array") != null
	var has_collector_def: bool = DataDB.get_building_def(&"regolith_collector") != null
	var has_refinery_def: bool = DataDB.get_building_def(&"refinery") != null
	print("[Smoke] Building def solar_array loaded: ", has_solar_def)
	print("[Smoke] Building def regolith_collector loaded: ", has_collector_def)
	print("[Smoke] Building def refinery loaded: ", has_refinery_def)

	var metal_amount: float = Sim.get_resource(&"metal")
	print("[Smoke] Start resources money=", Sim.get_resource(&"money"), " regolith=", Sim.get_resource(&"regolith"), " metal=", metal_amount, " power=", Sim.get_resource(&"power"), " oxygen=", Sim.get_resource(&"oxygen"))
	if not has_solar_def or not has_collector_def or not has_refinery_def:
		push_error("[Smoke] Missing building defs required for FIRST LANDING objectives.")
	if metal_amount >= 50.0:
		push_warning("[Smoke] Metal objective starts complete (expected < 50 for pacing).")
