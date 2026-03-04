extends Node

signal entity_spawned(entity_id: int)
signal entity_despawned(entity_id: int)
signal entity_updated(entity_id: int)
signal resources_changed(resources: Dictionary)
signal tick_advanced(tick_count: int)
signal fx_popup(world_pos: Vector2, text: String, kind: StringName)
signal fx_burst(world_pos: Vector2, kind: StringName)
signal alerts_changed(alerts: Array[String])

const TICKS_PER_SECOND: int = 20
const DT: float = 1.0 / float(TICKS_PER_SECOND)
const DEBUG: bool = false
const MOVE_EPSILON: float = 4.0
const CLANKER_DURABILITY_MAX: float = 100.0
const CLANKER_DECAY_IDLE_PER_SEC: float = 0.02
const CLANKER_DECAY_WORK_PER_SEC: float = 0.10
const TOW_FOLLOW_OFFSET: Vector2 = Vector2(-18.0, 10.0)

var next_entity_id: int = 1
var entities: Dictionary = {}
var resources: Dictionary[StringName, float] = {}
var tick_count: int = 0
var money_rate_per_sec: float = 0.0

var _accumulator: float = 0.0
var _launchpad_warning_printed: bool = false
var _resources_dirty: bool = false

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
		&"scrap": 0.0,
	}
	money_rate_per_sec = 0.05 / 60.0
	tick_count = 0
	_accumulator = 0.0
	_launchpad_warning_printed = false
	_resources_dirty = true
	emit_signal("resources_changed", resources.duplicate(true))
	emit_signal("alerts_changed", [] as Array[String])
	_resources_dirty = false

func step() -> void:
	tick_count += 1
	set_resource(&"money", get_resource(&"money") + (money_rate_per_sec * DT))
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
		elif t == &"scrap_broken" or String(t) == "scrap_broken":
			_handle_scrap_broken_command(cmd)

	_schedule_build_jobs()
	_update_constructing_buildings()
	_update_units_movement()
	_update_towing()
	_update_clanker_degradation()

	if _resources_dirty:
		emit_signal("resources_changed", resources.duplicate(true))
		_resources_dirty = false

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
		if DEBUG:
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
		if DEBUG:
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
	e["assigned_clankers"] = [] as Array[int]
	entities[entity_id] = e
	emit_signal("entity_updated", entity_id)
	if DEBUG:
		print("[Build] accepted def=", String(building_def_id), " id=", entity_id, " money=", get_resource(&"money"), " metal=", get_resource(&"metal"))

func _handle_launch_robot_command() -> void:
	if not has_completed_launchpad():
		if not _launchpad_warning_printed:
			if DEBUG:
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
	if DEBUG:
		print("[Launch] robot drop success: money=", get_resource(&"money"), " clankers+3")

func _handle_launch_earth_mission_command() -> void:
	if not has_completed_launchpad():
		if not _launchpad_warning_printed:
			if DEBUG:
				print("[Launch] blocked: no completed launchpad")
			_launchpad_warning_printed = true
		return
	_launchpad_warning_printed = false
	if get_resource(&"money") < 2.0:
		return
	set_resource(&"money", get_resource(&"money") - 2.0)
	money_rate_per_sec += 0.05 / 60.0
	if DEBUG:
		print("[Launch] earth mission success: money=", get_resource(&"money"), " rate=", money_rate_per_sec)

func _handle_scrap_broken_command(cmd: Dictionary) -> void:
	var broken_id: int = int(cmd.get("broken_id", -1))
	if broken_id <= 0 or not entities.has(broken_id):
		return
	var broken: Dictionary = entities[broken_id] as Dictionary
	if (broken.get("kind", &"") as StringName) != &"unit":
		return
	if not bool(broken.get("is_broken", false)):
		return
	if bool(broken.get("is_being_towed", false)):
		return

	var scrap_pos: Vector2 = _get_scrap_heap_pos()
	var broken_pos: Vector2 = broken.get("pos", Vector2.ZERO) as Vector2
	var nearest_id: int = -1
	var nearest_distance_sq: float = INF
	for idv: Variant in entities.keys():
		var candidate_id: int = int(idv)
		var candidate: Dictionary = entities[candidate_id] as Dictionary
		if (candidate.get("kind", &"") as StringName) != &"unit":
			continue
		if bool(candidate.get("is_broken", false)):
			continue
		var candidate_job: Dictionary = candidate.get("job", {"type": &"idle"}) as Dictionary
		var candidate_job_type: StringName = candidate_job.get("type", &"idle") as StringName
		if candidate_job_type == &"tow":
			continue
		var candidate_pos: Vector2 = candidate.get("pos", Vector2.ZERO) as Vector2
		var distance_sq: float = candidate_pos.distance_squared_to(broken_pos)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_id = candidate_id

	if nearest_id <= 0:
		if DEBUG:
			print("[Scrap] no available clanker for broken id=", broken_id)
		return

	var clanker: Dictionary = entities[nearest_id] as Dictionary
	var stack: Array[Dictionary] = clanker.get("job_stack", []) as Array[Dictionary]
	var current_job: Dictionary = clanker.get("job", {"type": &"idle"}) as Dictionary
	var current_job_type: StringName = current_job.get("type", &"idle") as StringName
	if current_job_type != &"idle":
		stack.append(current_job.duplicate(true) as Dictionary)
	clanker["job_stack"] = stack
	clanker["job"] = {
		"type": &"tow",
		"broken_id": broken_id,
		"scrap_pos": scrap_pos,
		"stage": &"pickup",
	}
	clanker["move_target"] = broken_pos
	clanker["has_move_target"] = true
	entities[nearest_id] = clanker

	broken["is_being_towed"] = true
	broken["towed_by_unit_id"] = nearest_id
	entities[broken_id] = broken
	if DEBUG:
		print("[Scrap] clanker ", nearest_id, " towing broken ", broken_id)
	emit_signal("entity_updated", nearest_id)
	emit_signal("entity_updated", broken_id)

func _schedule_build_jobs() -> void:
	var build_ids: Array[int] = []
	for idv: Variant in entities.keys():
		var build_id: int = int(idv)
		var build_entity: Dictionary = entities[build_id] as Dictionary
		if (build_entity.get("kind", &"") as StringName) != &"building":
			continue
		if not bool(build_entity.get("is_constructing", false)):
			continue
		build_ids.append(build_id)

	build_ids.sort()

	for build_id: int in build_ids:
		if not entities.has(build_id):
			continue
		var build_entity: Dictionary = entities[build_id] as Dictionary
		build_entity["assigned_clankers"] = [] as Array[int]
		entities[build_id] = build_entity

	for idv: Variant in entities.keys():
		var unit_id: int = int(idv)
		if not entities.has(unit_id):
			continue
		var unit_entity: Dictionary = entities[unit_id] as Dictionary
		if (unit_entity.get("kind", &"") as StringName) != &"unit":
			continue
		if bool(unit_entity.get("is_broken", false)):
			unit_entity["job"] = {"type": &"idle"}
			entities[unit_id] = unit_entity
			continue
		var unit_job: Dictionary = unit_entity.get("job", {"type": &"idle"}) as Dictionary
		var unit_job_type: StringName = unit_job.get("type", &"idle") as StringName
		if unit_job_type == &"tow":
			entities[unit_id] = unit_entity
			continue
		if unit_job_type == &"build":
			var keep_build_id: int = int(unit_job.get("build_id", -1))
			if keep_build_id > 0 and entities.has(keep_build_id):
				var keep_build: Dictionary = entities[keep_build_id] as Dictionary
				if bool(keep_build.get("is_constructing", false)):
					var keep_assigned: Array[int] = keep_build.get("assigned_clankers", []) as Array[int]
					keep_assigned.append(unit_id)
					keep_build["assigned_clankers"] = keep_assigned
					entities[keep_build_id] = keep_build
					continue
		unit_entity["job"] = {"type": &"idle"}
		entities[unit_id] = unit_entity

	if build_ids.is_empty():
		return

	var available_units: Array[int] = []
	for idv: Variant in entities.keys():
		var unit_id: int = int(idv)
		var unit_entity: Dictionary = entities[unit_id] as Dictionary
		if (unit_entity.get("kind", &"") as StringName) != &"unit":
			continue
		if bool(unit_entity.get("is_broken", false)):
			continue
		var unit_job: Dictionary = unit_entity.get("job", {"type": &"idle"}) as Dictionary
		if (unit_job.get("type", &"idle") as StringName) == &"idle":
			available_units.append(unit_id)

	available_units.sort()
	var build_count: int = build_ids.size()
	var index: int = 0
	for clanker_id: int in available_units:
		var build_id: int = build_ids[index % build_count]
		if not entities.has(clanker_id) or not entities.has(build_id):
			index += 1
			continue
		var clanker: Dictionary = entities[clanker_id] as Dictionary
		clanker["job"] = {"type": &"build", "build_id": build_id}
		entities[clanker_id] = clanker

		var build: Dictionary = entities[build_id] as Dictionary
		var assigned: Array[int] = build.get("assigned_clankers", []) as Array[int]
		assigned.append(clanker_id)
		build["assigned_clankers"] = assigned
		entities[build_id] = build
		index += 1

func _update_constructing_buildings() -> void:
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		if not entities.has(id):
			continue
		var e: Dictionary = entities[id] as Dictionary
		if (e.get("kind", &"") as StringName) != &"building":
			continue
		if not bool(e.get("is_constructing", false)):
			continue
		var assigned_clankers: Array[int] = e.get("assigned_clankers", []) as Array[int]
		var clanker_count: int = assigned_clankers.size()
		if clanker_count <= 0:
			continue
		var remaining: float = float(e.get("build_remaining", 0.0))
		remaining -= DT * float(clanker_count)
		e["build_remaining"] = max(remaining, 0.0)
		if remaining <= 0.0:
			e["is_constructing"] = false
			e["assigned_clankers"] = [] as Array[int]
			entities[id] = e
			emit_signal("entity_updated", id)
			for unit_id_v: Variant in entities.keys():
				var unit_id: int = int(unit_id_v)
				var unit: Dictionary = entities[unit_id] as Dictionary
				if (unit.get("kind", &"") as StringName) != &"unit":
					continue
				var job: Dictionary = unit.get("job", {"type": &"idle"}) as Dictionary
				if (job.get("type", &"idle") as StringName) != &"build":
					continue
				if int(job.get("build_id", -1)) == id:
					unit["job"] = {"type": &"idle"}
					entities[unit_id] = unit
					emit_signal("entity_updated", unit_id)
			var completed_pos: Vector2 = e.get("pos", Vector2.ZERO) as Vector2
			emit_signal("fx_burst", completed_pos, &"sparkle")
			if DEBUG:
				print("[Build] completed entity=", id)
			continue
		entities[id] = e
		emit_signal("entity_updated", id)

func _update_clanker_degradation() -> void:
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		if not entities.has(id):
			continue
		var e: Dictionary = entities[id] as Dictionary
		if (e.get("kind", &"") as StringName) != &"unit":
			continue
		if bool(e.get("is_broken", false)):
			continue
		var durability_before: float = float(e.get("durability", CLANKER_DURABILITY_MAX))
		var job: Dictionary = e.get("job", {"type": &"idle"}) as Dictionary
		var job_type: StringName = job.get("type", &"idle") as StringName
		var decay_per_sec: float = CLANKER_DECAY_IDLE_PER_SEC
		if job_type != &"idle":
			decay_per_sec = CLANKER_DECAY_WORK_PER_SEC
		var durability_after: float = clamp(durability_before - (decay_per_sec * DT), 0.0, CLANKER_DURABILITY_MAX)
		e["durability"] = durability_after

		var threshold_before: int = int(floor(durability_before))
		var threshold_after: int = int(floor(durability_after))
		var should_emit_update: bool = threshold_before != threshold_after
		if durability_after <= 0.0:
			var previous_job: Dictionary = e.get("job", {"type": &"idle"}) as Dictionary
			if (previous_job.get("type", &"idle") as StringName) == &"tow":
				var towed_id: int = int(previous_job.get("broken_id", -1))
				if towed_id > 0 and entities.has(towed_id):
					var towed: Dictionary = entities[towed_id] as Dictionary
					towed["is_being_towed"] = false
					towed["towed_by_unit_id"] = -1
					entities[towed_id] = towed
					emit_signal("entity_updated", towed_id)
			e["is_broken"] = true
			e["job"] = {"type": &"idle"}
			e["job_stack"] = [] as Array[Dictionary]
			e["has_move_target"] = false
			e["is_being_towed"] = false
			e["towed_by_unit_id"] = -1
			if DEBUG:
				print("[Clanker] broke: id=", id)
			should_emit_update = true

		entities[id] = e
		if should_emit_update:
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

func _update_towing() -> void:
	for idv: Variant in entities.keys():
		var clanker_id: int = int(idv)
		if not entities.has(clanker_id):
			continue
		var clanker: Dictionary = entities[clanker_id] as Dictionary
		if (clanker.get("kind", &"") as StringName) != &"unit":
			continue
		if bool(clanker.get("is_broken", false)):
			continue
		var job: Dictionary = clanker.get("job", {"type": &"idle"}) as Dictionary
		if (job.get("type", &"idle") as StringName) != &"tow":
			continue
		var broken_id: int = int(job.get("broken_id", -1))
		if broken_id <= 0 or not entities.has(broken_id):
			_resume_clanker_job(clanker_id)
			continue
		var broken: Dictionary = entities[broken_id] as Dictionary
		if not bool(broken.get("is_broken", false)):
			_resume_clanker_job(clanker_id)
			continue
		var clanker_pos: Vector2 = clanker.get("pos", Vector2.ZERO) as Vector2
		var broken_pos: Vector2 = broken.get("pos", Vector2.ZERO) as Vector2
		var scrap_pos: Vector2 = job.get("scrap_pos", _get_scrap_heap_pos()) as Vector2
		var stage: StringName = job.get("stage", &"pickup") as StringName
		var has_move_target: bool = bool(clanker.get("has_move_target", false))
		if not has_move_target:
			if stage == &"pickup":
				if clanker_pos.distance_to(broken_pos) > MOVE_EPSILON:
					clanker["move_target"] = broken_pos
					clanker["has_move_target"] = true
				else:
					job["stage"] = &"hauling"
					clanker["job"] = job
					clanker["move_target"] = scrap_pos
					clanker["has_move_target"] = true
				entities[clanker_id] = clanker
				emit_signal("entity_updated", clanker_id)
				continue
			if clanker_pos.distance_to(scrap_pos) <= MOVE_EPSILON:
				set_resource(&"scrap", get_resource(&"scrap") + 1.0)
				despawn_entity(broken_id)
				_resume_clanker_job(clanker_id)
				continue
			clanker["move_target"] = scrap_pos
			clanker["has_move_target"] = true
			entities[clanker_id] = clanker
			emit_signal("entity_updated", clanker_id)
			continue

		if stage == &"hauling":
			broken["pos"] = clanker_pos + TOW_FOLLOW_OFFSET
			entities[broken_id] = broken
			emit_signal("entity_updated", broken_id)

func _resume_clanker_job(clanker_id: int) -> void:
	if not entities.has(clanker_id):
		return
	var clanker: Dictionary = entities[clanker_id] as Dictionary
	var stack: Array[Dictionary] = clanker.get("job_stack", []) as Array[Dictionary]
	var resumed_job: Dictionary = {"type": &"idle"}
	if not stack.is_empty():
		resumed_job = stack.pop_back() as Dictionary
	clanker["job_stack"] = stack

	var resumed_type: StringName = resumed_job.get("type", &"idle") as StringName
	if resumed_type == &"build":
		var resumed_build_id: int = int(resumed_job.get("build_id", -1))
		if resumed_build_id <= 0 or not entities.has(resumed_build_id):
			resumed_job = {"type": &"idle"}
		else:
			var resumed_build: Dictionary = entities[resumed_build_id] as Dictionary
			if not bool(resumed_build.get("is_constructing", false)):
				resumed_job = {"type": &"idle"}
	clanker["job"] = resumed_job
	clanker["has_move_target"] = false
	entities[clanker_id] = clanker
	emit_signal("entity_updated", clanker_id)

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
		"assigned_clankers": [] as Array[int],
	}
	if resolved_kind == &"unit":
		var entity: Dictionary = entities[entity_id] as Dictionary
		entity["durability"] = CLANKER_DURABILITY_MAX
		entity["is_broken"] = false
		entity["job"] = {"type": &"idle"}
		entity["job_stack"] = [] as Array[Dictionary]
		entity["is_being_towed"] = false
		entity["towed_by_unit_id"] = -1
		entities[entity_id] = entity
	emit_signal("entity_spawned", entity_id)
	return entity_id

func is_clanker_available(entity_id: int) -> bool:
	if not entities.has(entity_id):
		return false
	var e: Dictionary = entities[entity_id] as Dictionary
	var kind: StringName = e.get("kind", &"") as StringName
	if kind != &"unit":
		return false
	if bool(e.get("is_broken", false)):
		return false
	var job: Dictionary = e.get("job", {"type": &"idle"}) as Dictionary
	var job_type: StringName = job.get("type", &"idle") as StringName
	return job_type == &"idle"

func get_available_clankers() -> Array[int]:
	var available: Array[int] = []
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		if is_clanker_available(id):
			available.append(id)
	return available

func get_active_build_sites() -> Array[int]:
	var active: Array[int] = []
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		var e: Dictionary = entities[id] as Dictionary
		var kind: StringName = e.get("kind", &"") as StringName
		if kind != &"building":
			continue
		var is_constructing: bool = bool(e.get("is_constructing", false))
		if is_constructing:
			active.append(id)
	return active

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
	_resources_dirty = true

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

func _get_scrap_heap_pos() -> Vector2:
	for idv: Variant in entities.keys():
		var id: int = int(idv)
		var e: Dictionary = entities[id] as Dictionary
		if (e.get("kind", &"") as StringName) != &"building":
			continue
		if (e.get("def_id", &"") as StringName) == &"scrap_heap":
			return e.get("pos", Vector2.ZERO) as Vector2
	return _get_command_dome_spawn_pos() + Vector2(100.0, 0.0)
