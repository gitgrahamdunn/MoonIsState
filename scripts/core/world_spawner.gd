extends Node2D

const UNIT_VIEW_SCENE := preload("res://scenes/units/UnitView.tscn")

var _unit_views: Dictionary = {}

func _ready() -> void:
	Sim.entity_spawned.connect(_on_entity_spawned)
	Sim.entity_despawned.connect(_on_entity_despawned)

func _on_entity_spawned(entity_id: int) -> void:
	var entity := Sim.get_entity(entity_id)
	if entity.is_empty():
		return
	if entity.get("kind", &"") != &"unit":
		return
	var unit_view := UNIT_VIEW_SCENE.instantiate()
	unit_view.entity_id = entity_id
	add_child(unit_view)
	_unit_views[entity_id] = unit_view

func _on_entity_despawned(entity_id: int) -> void:
	if not _unit_views.has(entity_id):
		return
	var unit_view: Node = _unit_views[entity_id]
	if is_instance_valid(unit_view):
		unit_view.queue_free()
	_unit_views.erase(entity_id)
