extends Node
class_name Sim

signal entity_spawned(entity_id: int)
signal entity_despawned(entity_id: int)
signal entity_updated(entity_id: int)
signal resources_changed(resources: Dictionary)

const TICKS_PER_SECOND := 20
const DT := 1.0 / TICKS_PER_SECOND
const MOVE_EPSILON := 4.0

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
	var commands := CommandBus.drain()
	for command in commands:
		_apply_command(command)
	_update_movement()

func spawn_entity(entity_type: StringName, pos: Vector2, owner_id: int) -> int:
	var entity_id := next_entity_id
	next_entity_id += 1
	var kind: StringName = &"building"
	if DataDB.get_unit_def(entity_type) != null:
		kind = &"unit"
	entities[entity_id] = {
		"id": entity_id,
		"owner_id": owner_id,
		"def_id": entity_type,
		"kind": kind,
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
	var command_type: Variant = command.get("type")
	if typeof(command_type) != TYPE_STRING and typeof(command_type) != TYPE_STRING_NAME:
		return
	if StringName(command_type) != &"move":
		return

	var target_pos: Vector2 = command.get("target_pos", Vector2.ZERO)
	var entity_ids: Array = command.get("entity_ids", [])
	for entity_id_variant in entity_ids:
		var entity_id := int(entity_id_variant)
		if not entities.has(entity_id):
			continue
		var entity: Dictionary = entities[entity_id]
		if entity.get("kind", &"") != &"unit":
			continue
		entity["move_target"] = target_pos
		entity["has_move_target"] = true
		entities[entity_id] = entity

func _update_movement() -> void:
	for entity_id in entities.keys():
		var entity: Dictionary = entities[entity_id]
		if not bool(entity.get("has_move_target", false)):
			continue
		if entity.get("kind", &"") != &"unit":
			continue

		var unit_def := DataDB.get_unit_def(entity.get("def_id", &""))
		if unit_def == null:
			continue

		var current_pos: Vector2 = entity.get("pos", Vector2.ZERO)
		var move_target: Vector2 = entity.get("move_target", current_pos)
		var to_target: Vector2 = move_target - current_pos
		var distance := to_target.length()
		if distance <= MOVE_EPSILON:
			entity["pos"] = move_target
			entity["vel"] = Vector2.ZERO
			entity["has_move_target"] = false
			entities[entity_id] = entity
			emit_signal("entity_updated", int(entity_id))
			continue

		var max_step := unit_def.move_speed * DT
		var direction := to_target / distance
		var step_distance := min(distance, max_step)
		var new_pos := current_pos + direction * step_distance
		entity["vel"] = direction * unit_def.move_speed
		entity["pos"] = new_pos
		if step_distance >= distance:
			entity["pos"] = move_target
			entity["vel"] = Vector2.ZERO
			entity["has_move_target"] = false
		entities[entity_id] = entity
		emit_signal("entity_updated", int(entity_id))
