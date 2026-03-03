extends Node2D

const TILE_SIZE: int = 16
const WORLD_SIZE: Vector2i = Vector2i(2200, 1400)
const CRATER_COUNT: int = 40
const REGOLITH_BASE: Color = Color(0.31, 0.31, 0.36, 1.0)
const REGOLITH_DARK: Color = Color(0.23, 0.23, 0.27, 1.0)
const REGOLITH_LIGHT: Color = Color(0.4, 0.4, 0.45, 1.0)

var _craters: Array[Dictionary] = []

func _ready() -> void:
	_generate_craters()
	queue_redraw()

func _draw() -> void:
	var tiles_x: int = int(ceili(float(WORLD_SIZE.x) / float(TILE_SIZE)))
	var tiles_y: int = int(ceili(float(WORLD_SIZE.y) / float(TILE_SIZE)))
	for ty: int in range(tiles_y):
		for tx: int in range(tiles_x):
			var tile_rect: Rect2 = Rect2(
				Vector2(float(tx * TILE_SIZE), float(ty * TILE_SIZE)),
				Vector2(float(TILE_SIZE), float(TILE_SIZE))
			)
			draw_rect(tile_rect, _sample_regolith_color(tx, ty), true)

	for crater: Dictionary in _craters:
		var center: Vector2 = crater["center"] as Vector2
		var radius: float = float(crater["radius"])
		draw_circle(center, radius + 2.0, Color(0.15, 0.15, 0.18, 0.5))
		draw_circle(center, radius, Color(0.37, 0.37, 0.42, 0.6))

func _sample_regolith_color(tile_x: int, tile_y: int) -> Color:
	var seed_value: int = ((tile_x + 17) * 92821) ^ ((tile_y + 41) * 68917)
	var t: int = abs(seed_value) % 100
	if t < 15:
		return REGOLITH_DARK
	if t > 86:
		return REGOLITH_LIGHT
	return REGOLITH_BASE

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
