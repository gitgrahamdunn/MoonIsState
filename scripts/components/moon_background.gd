extends Node2D

const BG_SIZE: float = 4000.0
const CRATER_COUNT: int = 220
const CRATER_SEED: int = 4601

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var half: float = BG_SIZE * 0.5
	var bg_rect: Rect2 = Rect2(Vector2(-half, -half), Vector2(BG_SIZE, BG_SIZE))
	draw_rect(bg_rect, Color(0.75, 0.76, 0.78, 1.0), true)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = CRATER_SEED
	for _i: int in range(CRATER_COUNT):
		var p: Vector2 = Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		var r: float = rng.randf_range(3.0, 11.0)
		var alpha: float = rng.randf_range(0.05, 0.15)
		draw_circle(p, r, Color(0.55, 0.56, 0.58, alpha))
