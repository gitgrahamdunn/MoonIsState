extends Node2D

const BUILDING_SIZE := Vector2i(44, 44)

@export var entity_id: int = -1

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_ensure_placeholder_texture()
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()

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

func _ensure_placeholder_texture() -> void:
	if sprite.texture != null:
		return
	var image := Image.create(BUILDING_SIZE.x, BUILDING_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.7, 1.0, 1.0))
	var texture := ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.centered = true
