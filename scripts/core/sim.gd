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

	var commands: Array[Dictionary] = CommandBus.drain()
	for command in commands:
		_apply_command(command)

	_update_movement()

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

func _apply_command(command: Dictionary) -> void:
	var command_type_variant: Variant = command.get("type")
	if typeof(command_type_variant) != TYPE_STRING and typeof(command_type_variant) != TYPE_STRING_NAME:
		return
	var command_type: StringName = StringName(command_type_variant)
	if command_type != &"move":
		return

	var target_pos: Vector2 = command.get("target_pos", Vector2.ZERO) as Vector2
	var entity_ids: Array = command.get("entity_ids", []) as Array
	for entity_id_variant in entity_ids:
		var entity_id: int = int(entity_id_variant)
		if not entities.has(entity_id):
			continue
		var entity: Dictionary = entities[entity_id] as Dictionary
		var kind: StringName = entity.get("kind", &"") as StringName
		if kind != &"unit":
			continue
		entity["move_target"] = target_pos
		entity["has_move_target"] = true
		entities[entity_id] = entity

func _update_movement() -> void:
	for entity_id_variant in entities.keys():
		var entity_id: int = int(entity_id_variant)
		var entity: Dictionary = entities[entity_id] as Dictionary
		var has_move_target: bool = bool(entity.get("has_move_target", false))
		if not has_move_target:
			continue
		var kind: StringName = entity.get("kind", &"") as StringName
		if kind != &"unit":
			continue

		var def_id: StringName = entity.get("def_id", &"") as StringName
		var unit_def: UnitDef = DataDB.get_unit_def(def_id)
		if unit_def == null:
			continue

		var pos: Vector2 = entity.get("pos", Vector2.ZERO) as Vector2
		var target: Vector2 = entity.get("move_target", pos) as Vector2
		var speed: float = float(unit_def.move_speed)
		var new_pos: Vector2 = pos.move_toward(target, speed * DT)
		var moved: bool = new_pos.distance_to(pos) > 0.001
		entity["pos"] = new_pos
		if moved:
			var direction: Vector2 = (new_pos - pos).normalized()
			entity["vel"] = direction * speed
		else:
			entity["vel"] = Vector2.ZERO
		if new_pos.distance_to(target) <= MOVE_EPSILON:
			entity["pos"] = target
			entity["vel"] = Vector2.ZERO
			entity["has_move_target"] = false
		entities[entity_id] = entity
		if moved or not bool(entity.get("has_move_target", false)):
			emit_signal("entity_updated", entity_id)
