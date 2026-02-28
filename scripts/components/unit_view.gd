extends Node2D

const BODY_RADIUS := 12.0

@export var entity_id: int = -1

@onready var sprite: Sprite2D = $Sprite2D
@onready var selection_ring: Node2D = $SelectionRing

func _ready() -> void:
	add_to_group("unit_views")
	_ensure_placeholder_texture()
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()

func _exit_tree() -> void:
	remove_from_group("unit_views")

func _process(_delta: float) -> void:
	if is_instance_valid(selection_ring):
		selection_ring.call("set_selected", _is_selected())

func _on_entity_updated(updated_entity_id: int) -> void:
	if updated_entity_id != entity_id:
		return
	_update_from_sim()

func _update_from_sim() -> void:
	if entity_id < 0:
		return
	var entity := Sim.get_entity(entity_id)
	if entity.is_empty():
		return
	global_position = entity.get("pos", global_position)

func _is_selected() -> bool:
	for node in get_tree().get_nodes_in_group("selection_manager"):
		if node.has_method("is_entity_selected"):
			return node.is_entity_selected(entity_id)
	return false

func _ensure_placeholder_texture() -> void:
	if sprite.texture != null:
		return
	var image := Image.create(int(BODY_RADIUS * 2.0), int(BODY_RADIUS * 2.0), false, Image.FORMAT_RGBA8)
	image.fill(Color(0.9, 0.9, 1.0, 1.0))
	var texture := ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.centered = true
