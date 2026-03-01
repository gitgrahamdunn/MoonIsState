extends Node2D

const BODY_RADIUS: float = 12.0

@export var entity_id: int = -1

var _selected: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("unit_views")
	_ensure_placeholder_texture()
	Sim.entity_updated.connect(_on_entity_updated)
	_update_from_sim()

func _exit_tree() -> void:
	remove_from_group("unit_views")

func get_entity_id() -> int:
	return entity_id

func get_world_pos() -> Vector2:
	return global_position

func set_selected(v: bool) -> void:
	if _selected == v:
		return
	_selected = v
	queue_redraw()

func _draw() -> void:
	if _selected:
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 1.0), 2.0)

func _on_entity_updated(updated_entity_id: int) -> void:
	if updated_entity_id != entity_id:
		return
	_update_from_sim()

func _update_from_sim() -> void:
	if entity_id < 0:
		return
	var e: Dictionary = Sim.get_entity(entity_id)
	if e.is_empty():
		return
	global_position = e.get("pos", global_position) as Vector2

func _ensure_placeholder_texture() -> void:
	if sprite.texture != null:
		sprite.centered = true
		return
	var diameter: int = int(BODY_RADIUS * 2.0)
	var image: Image = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.9, 0.9, 1.0, 1.0))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.centered = true
