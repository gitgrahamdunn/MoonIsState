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
	print("[DataDB] loaded counts units=", units.size(), " buildings=", buildings.size(), " tech=", tech.size())

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
		if dir.current_is_dir():
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
