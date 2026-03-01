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
var resources: Dictionary = {}
var tick_count: int = 0

var _accumulator: float = 0.0

func _process(delta: float) -> void:
	_accumulator += delta
	while _accumulator >= DT:
		step()
		_accumulator -= DT

func reset() -> void:
	next_entity_id = 1
	entities.clear()
	resources = {
		&"regolith": 0,
		&"metal": 0,
		&"power": 0,
		&"oxygen": 0,
	}
	tick_count = 0
	_accumulator = 0.0
	emit_signal("resources_changed", resources.duplicate(true))

func step() -> void:
	tick_count += 1
	emit_signal("tick_advanced", tick_count)

	var cmds: Array[Dictionary] = CommandBus.drain()
	for cmd in cmds:
		var t: StringName = cmd.get("type", "") as StringName
		if t == &"move" or String(t) == "move":
			var ids: Array = cmd.get("entity_ids", []) as Array
			var target: Vector2 = cmd.get("target_pos", Vector2.ZERO) as Vector2
			for idv in ids:
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

	for idv in entities.keys():
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

func set_resource(name: StringName, value: int) -> void:
	resources[name] = value
	emit_signal("resources_changed", resources.duplicate(true))

func add_resource(name: StringName, delta: int) -> void:
	set_resource(name, int(resources.get(name, 0)) + delta)
