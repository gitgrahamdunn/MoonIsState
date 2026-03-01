extends Node

var units: Dictionary = {}
var buildings: Dictionary = {}
var tech: Dictionary = {}

func load_all() -> void:
	units.clear()
	buildings.clear()
	tech.clear()
	ensure_sample_data_exists()
	print("[DataDB] scanning: ", "res://data")
	_scan_dir("res://data")
	print("[DataDB] loaded counts units=", units.size(), " buildings=", buildings.size(), " tech=", tech.size())

func ensure_sample_data_exists() -> void:
	var units_dir_err: Error = DirAccess.make_dir_recursive_absolute("res://data/units")
	if units_dir_err != OK:
		push_warning("[DataDB] failed to ensure directory: res://data/units err=%s" % units_dir_err)

	var buildings_dir_err: Error = DirAccess.make_dir_recursive_absolute("res://data/buildings")
	if buildings_dir_err != OK:
		push_warning("[DataDB] failed to ensure directory: res://data/buildings err=%s" % buildings_dir_err)

	var tech_dir_err: Error = DirAccess.make_dir_recursive_absolute("res://data/tech")
	if tech_dir_err != OK:
		push_warning("[DataDB] failed to ensure directory: res://data/tech err=%s" % tech_dir_err)

	var worker_path: String = "res://data/units/worker.tres"
	if not ResourceLoader.exists(worker_path):
		var worker: UnitDef = UnitDef.new()
		worker.id = &"worker"
		worker.display_name = "Worker"
		worker.move_speed = 120.0
		var worker_save_err: Error = ResourceSaver.save(worker, worker_path)
		if worker_save_err == OK:
			print("[DataDB] wrote sample def: ", worker_path)
		else:
			push_warning("[DataDB] failed to write sample def: %s err=%s" % [worker_path, worker_save_err])

	var soldier_path: String = "res://data/units/soldier.tres"
	if not ResourceLoader.exists(soldier_path):
		var soldier: UnitDef = UnitDef.new()
		soldier.id = &"soldier"
		soldier.display_name = "Soldier"
		soldier.move_speed = 110.0
		var soldier_save_err: Error = ResourceSaver.save(soldier, soldier_path)
		if soldier_save_err == OK:
			print("[DataDB] wrote sample def: ", soldier_path)
		else:
			push_warning("[DataDB] failed to write sample def: %s err=%s" % [soldier_path, soldier_save_err])

	var command_dome_path: String = "res://data/buildings/command_dome.tres"
	if not ResourceLoader.exists(command_dome_path):
		var command_dome: BuildingDef = BuildingDef.new()
		command_dome.id = &"command_dome"
		command_dome.display_name = "Command Dome"
		var command_dome_save_err: Error = ResourceSaver.save(command_dome, command_dome_path)
		if command_dome_save_err == OK:
			print("[DataDB] wrote sample def: ", command_dome_path)
		else:
			push_warning("[DataDB] failed to write sample def: %s err=%s" % [command_dome_path, command_dome_save_err])

	var solar_array_path: String = "res://data/buildings/solar_array.tres"
	if not ResourceLoader.exists(solar_array_path):
		var solar_array: BuildingDef = BuildingDef.new()
		solar_array.id = &"solar_array"
		solar_array.display_name = "Solar Array"
		var solar_array_save_err: Error = ResourceSaver.save(solar_array, solar_array_path)
		if solar_array_save_err == OK:
			print("[DataDB] wrote sample def: ", solar_array_path)
		else:
			push_warning("[DataDB] failed to write sample def: %s err=%s" % [solar_array_path, solar_array_save_err])

	var improved_panels_path: String = "res://data/tech/improved_panels.tres"
	if not ResourceLoader.exists(improved_panels_path):
		var improved_panels: TechDef = TechDef.new()
		improved_panels.id = &"improved_panels"
		improved_panels.display_name = "Improved Panels"
		var improved_panels_save_err: Error = ResourceSaver.save(improved_panels, improved_panels_path)
		if improved_panels_save_err == OK:
			print("[DataDB] wrote sample def: ", improved_panels_path)
		else:
			push_warning("[DataDB] failed to write sample def: %s err=%s" % [improved_panels_path, improved_panels_save_err])

func get_unit_def(id: StringName) -> UnitDef:
	return units.get(id)

func get_building_def(id: StringName) -> BuildingDef:
	return buildings.get(id)

func get_tech_def(id: StringName) -> TechDef:
	return tech.get(id)

func _scan_dir(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_warning("DataDB could not open directory: %s" % path)
		return

	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.begins_with("."):
			fname = dir.get_next()
			continue

		var full_path: String = path.path_join(fname)
		var is_dir: bool = dir.current_is_dir()
		print("[DataDB] entry: ", full_path, " dir=", is_dir)
		if is_dir:
			print("[DataDB] scanning: ", full_path)
			_scan_dir(full_path)
		elif fname.ends_with(".tres") or fname.ends_with(".res"):
			print("[DataDB] found file: ", full_path)
			_load_resource(full_path)
		fname = dir.get_next()
	dir.list_dir_end()

func _load_resource(path: String) -> void:
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		push_warning("[DataDB] failed load: %s" % path)
		return

	if res is UnitDef:
		var unit: UnitDef = res as UnitDef
		units[unit.id] = unit
		print("[DataDB] loaded UnitDef: ", unit.id)
	elif res is BuildingDef:
		var building: BuildingDef = res as BuildingDef
		buildings[building.id] = building
		print("[DataDB] loaded BuildingDef: ", building.id)
	elif res is TechDef:
		var technology: TechDef = res as TechDef
		tech[technology.id] = technology
		print("[DataDB] loaded TechDef: ", technology.id)
