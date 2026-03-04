extends Node2D

const UNIT_VIEW_SCENE := preload("res://scenes/units/UnitView.tscn")
const BUILDING_VIEW_SCENE := preload("res://scenes/buildings/BuildingView.tscn")

var _entity_views: Dictionary = {}

func _ready() -> void:
	Sim.entity_spawned.connect(_on_entity_spawned)
	Sim.entity_despawned.connect(_on_entity_despawned)
	call_deferred("_seed_existing_entities")

func _seed_existing_entities() -> void:
	var count: int = 0
	for idv: Variant in Sim.entities.keys():
		_on_entity_spawned(int(idv))
		count += 1
	print("[WorldSpawner] seeded views for existing entities: ", count)

func _on_entity_spawned(entity_id: int) -> void:
	var entity: Dictionary = Sim.get_entity(entity_id)
	if entity.is_empty():
		return

	var kind: StringName = entity.get("kind", &"") as StringName
	var view: Node2D = null
	if kind == &"unit":
		view = UNIT_VIEW_SCENE.instantiate()
	elif kind == &"building":
		view = BUILDING_VIEW_SCENE.instantiate()
	else:
		return

	view.entity_id = entity_id
	add_child(view)
	_entity_views[entity_id] = view

func _on_entity_despawned(entity_id: int) -> void:
	if not _entity_views.has(entity_id):
		return
	var view: Node = _entity_views[entity_id]
	if is_instance_valid(view):
		view.queue_free()
	_entity_views.erase(entity_id)
