extends Node2D

const AssetFactory = preload("res://scripts/core/asset_factory.gd")

const TILE_SIZE: int = 16
const WORLD_SIZE: Vector2i = Vector2i(2200, 1400)
const CRATER_COUNT: int = 40

var _craters: Array[Dictionary] = []

func _ready() -> void:
	_generate_craters()
	queue_redraw()

func _draw() -> void:
	var tile_tex: Texture2D = AssetFactory.get_regolith_tile()
	var crater_tex: Texture2D = AssetFactory.get_crater_decal()
	var tiles_x: int = int(ceili(float(WORLD_SIZE.x) / float(TILE_SIZE)))
	var tiles_y: int = int(ceili(float(WORLD_SIZE.y) / float(TILE_SIZE)))
	for ty: int in range(tiles_y):
		for tx: int in range(tiles_x):
			var tile_pos: Vector2 = Vector2(float(tx * TILE_SIZE), float(ty * TILE_SIZE))
			draw_texture(tile_tex, tile_pos)

	var crater_size: Vector2 = crater_tex.get_size()
	for crater: Dictionary in _craters:
		var center: Vector2 = crater.get("center", Vector2.ZERO) as Vector2
		draw_texture(crater_tex, center - (crater_size * 0.5))

func _generate_craters() -> void:
	_craters.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 19940316
	for _i: int in range(CRATER_COUNT):
		var radius: float = rng.randf_range(8.0, 28.0)
		var center: Vector2 = Vector2(
			rng.randf_range(radius, float(WORLD_SIZE.x) - radius),
			rng.randf_range(radius, float(WORLD_SIZE.y) - radius)
		)
		_craters.append({
			"center": center,
			"radius": radius,
		})
