extends Node

var units: Dictionary = {}
var buildings: Dictionary = {}
var tech: Dictionary = {}

func load_all() -> void:
	units.clear()
	buildings.clear()
	tech.clear()
	print("[DataDB] scanning: ", "res://data")
	_scan_dir("res://data")
	if units.is_empty() and buildings.is_empty() and tech.is_empty():
		print("[DataDB] scan produced 0 defs; trying direct known paths fallback...")
		_try_load_known_defs()
	print("[DataDB] loaded counts units=", units.size(), " buildings=", buildings.size(), " tech=", tech.size())

func _try_load_known_defs() -> void:
	var paths: Array[String] = [
		"res://data/units/worker.tres",
		"res://data/units/soldier.tres",
		"res://data/buildings/command_dome.tres",
		"res://data/buildings/solar_array.tres",
		"res://data/tech/improved_panels.tres",
	]
	for p: String in paths:
		var exists: bool = ResourceLoader.exists(p)
		print("[DataDB] exists? ", p, " -> ", exists)
		if exists:
			var res: Resource = ResourceLoader.load(p)
			print("[DataDB] load ", p, " -> ", res)
			if res == null:
				continue
			if res is UnitDef:
				var u: UnitDef = res as UnitDef
				units[u.id] = u
				print("[DataDB] direct loaded UnitDef ", u.id)
			elif res is BuildingDef:
				var b: BuildingDef = res as BuildingDef
				buildings[b.id] = b
				print("[DataDB] direct loaded BuildingDef ", b.id)
			elif res is TechDef:
				var t: TechDef = res as TechDef
				tech[t.id] = t
				print("[DataDB] direct loaded TechDef ", t.id)
			else:
				print("[DataDB] direct load unexpected type for ", p)

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
			_scan_dir(full_path)
		else:
			var load_path: String = full_path
			if load_path.ends_with(".tres.remap"):
				load_path = load_path.substr(0, load_path.length() - ".remap".length())
			if not load_path.ends_with(".tres"):
				fname = dir.get_next()
				continue
			if not ResourceLoader.exists(load_path):
				print("[DataDB] skip missing: ", load_path)
				fname = dir.get_next()
				continue
			_load_resource(load_path)
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
