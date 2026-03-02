extends Node

signal entity_spawned(entity_id: int)
signal entity_despawned(entity_id: int)
signal entity_updated(entity_id: int)
signal resources_changed(resources: Dictionary)
signal tick_advanced(tick_count: int)

const TICKS_PER_SECOND: int = 20
const DT: float = 1.0 / float(TICKS_PER_SECOND)
const MOVE_EPSILON: float = 4.0

var next_entity_id: int = 1
var entities: Dictionary = {}
var resources: Dictionary[StringName, float] = {}
var tick_count: int = 0
var money_rate_per_sec: float = 0.0

var _accumulator: float = 0.0
var _launchpad_warning_printed: bool = false

func _process(delta: float) -> void:
	_accumulator += delta
	while _accumulator >= DT:
		step()
		_accumulator -= DT

func reset() -> void:
	next_entity_id = 1
	entities.clear()
	resources = {
		&"money": 5.0,
		&"regolith": 0.0,
		&"metal": 0.0,
		&"power": 0.0,
		&"oxygen": 0.0,
	}
	money_rate_per_sec = 0.05 / 60.0
	tick_count = 0
	_accumulator = 0.0
	_launchpad_warning_printed = false
	emit_signal("resources_changed", resources.duplicate(true))

func step() -> void:
	tick_count += 1
	resources[&"money"] = get_resource(&"money") + (money_rate_per_sec * DT)
	emit_signal("resources_changed", resources.duplicate(true))
	emit_signal("tick_advanced", tick_count)

	var cmds: Array[Dictionary] = CommandBus.drain()
	for cmd: Dictionary in cmds:
		var t: StringName = cmd.get("type", "") as StringName
		if t == &"move" or String(t) == "move":
			_handle_move_command(cmd)
		elif t == &"build" or String(t) == "build":
			_handle_build_command(cmd)
		elif t == &"launch_robot" or String(t) == "launch_robot":
			_handle_launch_robot_command()
		elif t == &"launch_earth_mission" or String(t) == "launch_earth_mission":
			_handle_launch_earth_mission_command()

	_update_constructing_buildings()
	_update_units_movement()

func _handle_move_command(cmd: Dictionary) -> void:
	var ids: Array = cmd.get("entity_ids", []) as Array
	var target: Vector2 = cmd.get("target_pos", Vector2.ZERO) as Vector2
	for idv: Variant in ids:
		var id: int = int(idv)
		if not entities.has(id):
			continue
		var e: Dictionary = entities[id] as Dictionary
		var kind: StringName = e.get("kind", &"") as StringName
		if kind != &"unit":
			continue
		e["move_target"] = target
		e["has_move_target"] = true
		entities[id] = e
		print("[Sim] set move target for ", id, " -> ", target)

func _handle_build_command(cmd: Dictionary) -> void:
	var building_def_id: StringName = cmd.get("building_def", &"") as StringName
	if not DataDB.buildings.has(building_def_id):
		push_warning("[Build] Unknown building def: %s" % String(building_def_id))
		return
	var building_def: BuildingDef = DataDB.get_building_def(building_def_id)
	if building_def == null:
		return
	var builder_id: int = int(cmd.get("builder_id", -1))
	if not entities.has(builder_id):
		return
	var builder: Dictionary = entities[builder_id] as Dictionary
	var builder_kind: StringName = builder.get("kind", &"") as StringName
	if builder_kind != &"unit":
		return

	var needed_money: float = building_def.cost_money
	var needed_metal: float = building_def.cost_metal
	if get_resource(&"money") < needed_money or get_resource(&"metal") < needed_metal:
		print("[Build] Not enough resources for ", String(building_def_id))
		return

	set_resource(&"money", get_resource(&"money") - needed_money)
	set_resource(&"metal", get_resource(&"metal") - needed_metal)

	var build_pos: Vector2 = cmd.get("pos", Vector2.ZERO) as Vector2
	var entity_id: int = spawn_entity(building_def_id, build_pos, 1, &"building")
	var e: Dictionary = entities[entity_id] as Dictionary
	var build_time_total: float = building_def.build_time_sec
	if build_time_total <= 0.0:
		build_time_total = building_def.build_time
	e["is_constructing"] = build_time_total > 0.0
	e["build_remaining"] = build_time_total
	e["build_total"] = build_time_total
	entities[entity_id] = e
	emit_signal("entity_updated", entity_id)
	print("[Build] accepted def=", String(building_def_id), " id=", entity_id, " money=", get_resource(&"money"), " metal=", get_resource(&"metal"))

func _handle_launch_robot_command() -> void:
	if not has_completed_launchpad():
		if not _launchpad_warning_printed:
			print("[Launch] blocked: no completed launchpad")
			_launchpad_warning_printed = true
		return
	_launchpad_warning_printed = false
	if get_resource(&"money") < 1.0:
		return
	set_resource(&"money", get_resource(&"money") - 1.0)
	var spawn_pos: Vector2 = _get_command_dome_spawn_pos()
	spawn_entity(&"worker", spawn_pos + Vector2(20.0, 0.0), 1, &"unit")
	spawn_entity(&"worker", spawn_pos + Vector2(36.0, 12.0), 1, &"unit")
	spawn_entity(&"worker", spawn_pos + Vector2(36.0, -12.0), 1, &"unit")
	print("[Launch] robot drop success: money=", get_resource(&"money"), " workers+3")

func _handle_launch_earth_mission_command() -> void:
	if not has_completed_launchpad():
		if not _launchpad_warning_printed:
			print("[Launch] blocked: no completed launchpad")
			_launchpad_warning_printed = true
		return
	_launchpad_warning_printed = false
	if get_resource(&"money") < 2.0:
		return
	set_resource(&"money", get_resource(&"money") - 2.0)
	money_rate_per_sec += 0.05 / 60.0
	print("[Launch] earth mission success: money=", get_resource(&"money"), " rate=", money_rate_per_sec)

func _update_constructing_buildings() -> void:
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		var e: Dictionary = entities[id] as Dictionary
		var kind: StringName = e.get("kind", &"") as StringName
		if kind != &"building":
			continue
		var is_constructing: bool = bool(e.get("is_constructing", false))
		if not is_constructing:
			continue
		var remaining: float = float(e.get("build_remaining", 0.0))
		remaining -= DT
		e["build_remaining"] = max(remaining, 0.0)
		if remaining <= 0.0:
			e["is_constructing"] = false
			print("[Build] completed entity=", id)
		entities[id] = e
		emit_signal("entity_updated", id)

func _update_units_movement() -> void:
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		var e: Dictionary = entities[id] as Dictionary
		var kind: StringName = e.get("kind", &"") as StringName
		if kind != &"unit":
			continue
		var has_t: bool = bool(e.get("has_move_target", false))
		if not has_t:
			continue
		var pos: Vector2 = e.get("pos", Vector2.ZERO) as Vector2
		var target: Vector2 = e.get("move_target", pos) as Vector2
		var def_id: StringName = e.get("def_id", &"") as StringName
		var speed: float = 120.0
		var unit_def: UnitDef = DataDB.get_unit_def(def_id)
		if unit_def != null:
			speed = float(unit_def.move_speed)
		var step_dist: float = speed * DT
		var new_pos: Vector2 = pos.move_toward(target, step_dist)
		e["pos"] = new_pos
		if new_pos.distance_to(target) <= MOVE_EPSILON:
			e["pos"] = target
			e["has_move_target"] = false
		entities[id] = e
		emit_signal("entity_updated", int(id))

func spawn_entity(def_id: StringName, pos: Vector2, owner_id: int, kind: StringName = &"") -> int:
	var entity_id: int = next_entity_id
	next_entity_id += 1
	var resolved_kind: StringName = kind
	if resolved_kind == &"":
		if DataDB.units.has(def_id):
			resolved_kind = &"unit"
		elif DataDB.buildings.has(def_id):
			resolved_kind = &"building"
		else:
			resolved_kind = &"unknown"
	entities[entity_id] = {
		"id": entity_id,
		"owner_id": owner_id,
		"def_id": def_id,
		"kind": resolved_kind,
		"pos": pos,
		"vel": Vector2.ZERO,
		"move_target": Vector2.ZERO,
		"has_move_target": false,
		"is_constructing": false,
		"build_remaining": 0.0,
		"build_total": 0.0,
	}
	emit_signal("entity_spawned", entity_id)
	return entity_id

func despawn_entity(entity_id: int) -> void:
	if not entities.has(entity_id):
		return
	entities.erase(entity_id)
	emit_signal("entity_despawned", entity_id)

func get_entity(entity_id: int) -> Dictionary:
	if not entities.has(entity_id):
		return {}
	return entities[entity_id].duplicate(true)

func set_resource(name: StringName, value: float) -> void:
	resources[name] = value
	emit_signal("resources_changed", resources.duplicate(true))

func add_resource(name: StringName, delta: float) -> void:
	set_resource(name, get_resource(name) + delta)

func get_resource(name: StringName) -> float:
	return float(resources.get(name, 0.0))

func has_completed_launchpad() -> bool:
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		var e: Dictionary = entities[id] as Dictionary
		var kind: StringName = e.get("kind", &"") as StringName
		if kind != &"building":
			continue
		var def_id: StringName = e.get("def_id", &"") as StringName
		if def_id != &"launchpad":
			continue
		var is_constructing: bool = bool(e.get("is_constructing", false))
		if not is_constructing:
			return true
	return false

func _get_command_dome_spawn_pos() -> Vector2:
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		var e: Dictionary = entities[id] as Dictionary
		var kind: StringName = e.get("kind", &"") as StringName
		if kind != &"building":
			continue
		var def_id: StringName = e.get("def_id", &"") as StringName
		if def_id == &"command_dome":
			return e.get("pos", Vector2.ZERO) as Vector2
	return Vector2.ZERO
