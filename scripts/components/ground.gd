extends Node2D

const AssetFactory = preload("res://scripts/core/asset_factory.gd")

const TILE_SIZE: int = 16
const CRATER_COUNT: int = 40
const CRATER_WORLD_RADIUS: float = 4200.0
const CAM_EPSILON: float = 0.05
const SAFE_FALLBACK_HALF_EXTENT: int = 320

var _craters: Array[Dictionary] = []
var _last_cam_pos: Vector2 = Vector2.INF
var _last_cam_zoom: Vector2 = Vector2.INF

func _ready() -> void:
	_generate_craters()
	queue_redraw()

func _process(_delta: float) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var moved: bool = _last_cam_pos.distance_squared_to(cam.global_position) > (CAM_EPSILON * CAM_EPSILON)
	var zoomed: bool = _last_cam_zoom.distance_squared_to(cam.zoom) > (CAM_EPSILON * CAM_EPSILON)
	if moved or zoomed:
		_last_cam_pos = cam.global_position
		_last_cam_zoom = cam.zoom
		queue_redraw()

func _draw() -> void:
	var tile_tex: Texture2D = AssetFactory.get_regolith_tile()
	var crater_tex: Texture2D = AssetFactory.get_crater_decal()
	if tile_tex == null:
		return

	var visible_rect: Rect2 = _get_visible_world_rect()
	var x0: int = int(floor(visible_rect.position.x / float(TILE_SIZE)))
	var y0: int = int(floor(visible_rect.position.y / float(TILE_SIZE)))
	var x1: int = int(ceil((visible_rect.position.x + visible_rect.size.x) / float(TILE_SIZE)))
	var y1: int = int(ceil((visible_rect.position.y + visible_rect.size.y) / float(TILE_SIZE)))

	for ty: int in range(y0, y1 + 1):
		for tx: int in range(x0, x1 + 1):
			var tile_pos: Vector2 = Vector2(float(tx * TILE_SIZE), float(ty * TILE_SIZE))
			draw_texture(tile_tex, tile_pos)

	if crater_tex == null:
		return

	var crater_size: Vector2 = crater_tex.get_size()
	for crater: Dictionary in _craters:
		var center: Vector2 = crater.get("center", Vector2.ZERO) as Vector2
		var crater_radius: float = float(crater.get("radius", 0.0))
		var crater_rect: Rect2 = Rect2(center - Vector2(crater_radius, crater_radius), Vector2.ONE * crater_radius * 2.0)
		if not visible_rect.intersects(crater_rect):
			continue
		draw_texture(crater_tex, center - (crater_size * 0.5))

func _get_visible_world_rect() -> Rect2:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		var fallback_half: float = float(SAFE_FALLBACK_HALF_EXTENT * TILE_SIZE)
		return Rect2(Vector2(-fallback_half, -fallback_half), Vector2(fallback_half * 2.0, fallback_half * 2.0))

	var vp: Vector2 = get_viewport_rect().size
	var half_extents: Vector2 = (vp * 0.5) * cam.zoom
	var top_left: Vector2 = cam.global_position - half_extents
	var bottom_right: Vector2 = cam.global_position + half_extents
	var margin: float = float(TILE_SIZE)
	top_left -= Vector2.ONE * margin
	bottom_right += Vector2.ONE * margin
	return Rect2(top_left, bottom_right - top_left)

func _generate_craters() -> void:
	_craters.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 19940316
	for _i: int in range(CRATER_COUNT):
		var radius: float = rng.randf_range(8.0, 28.0)
		var center: Vector2 = Vector2(
			rng.randf_range(-CRATER_WORLD_RADIUS, CRATER_WORLD_RADIUS),
			rng.randf_range(-CRATER_WORLD_RADIUS, CRATER_WORLD_RADIUS)
		)
		_craters.append({
			"center": center,
			"radius": radius,
		})
