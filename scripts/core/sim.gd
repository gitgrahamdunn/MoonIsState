extends Node
class_name Sim

signal entity_spawned(entity_id: int)
signal entity_despawned(entity_id: int)
signal resources_changed(resources: Dictionary)

const TICKS_PER_SECOND := 20
const DT := 1.0 / TICKS_PER_SECOND

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

func spawn_entity(entity_type: StringName, pos: Vector2, owner_id: int) -> int:
	var entity_id := next_entity_id
	next_entity_id += 1
	entities[entity_id] = {
		"id": entity_id,
		"entity_type": entity_type,
		"position": pos,
		"owner_id": owner_id,
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

	match StringName(command_type):
		&"spawn_entity":
			spawn_entity(
				command.get("entity_type", &"unknown"),
				command.get("position", Vector2.ZERO),
				int(command.get("owner_id", 0))
			)
		&"despawn_entity":
			despawn_entity(int(command.get("entity_id", -1)))
		&"set_resource":
			set_resource(StringName(command.get("name", &"")), int(command.get("value", 0)))
		&"add_resource":
			add_resource(StringName(command.get("name", &"")), int(command.get("delta", 0)))
		_:
			pass
