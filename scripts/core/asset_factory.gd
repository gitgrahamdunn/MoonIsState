extends RefCounted

const OUTLINE: Color = Color(0.08, 0.09, 0.12, 1.0)
const TRANSPARENT: Color = Color(0.0, 0.0, 0.0, 0.0)
const WHITE: Color = Color(0.9, 0.92, 0.95, 1.0)
const GRAY: Color = Color(0.58, 0.62, 0.7, 1.0)
const DARK_GRAY: Color = Color(0.33, 0.37, 0.43, 1.0)
const BLUE: Color = Color(0.28, 0.53, 0.85, 1.0)
const LIGHT_BLUE: Color = Color(0.63, 0.83, 0.98, 1.0)
const ORANGE: Color = Color(0.96, 0.62, 0.24, 1.0)
const GLOW: Color = Color(1.0, 0.8, 0.42, 0.8)
const CARDINAL_NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

static var _cache: Dictionary[StringName, Texture2D] = {}

static func get_tex(key: StringName) -> Texture2D:
	var cached: Variant = _cache.get(key)
	if cached is Texture2D:
		return cached as Texture2D

	var image: Image
	match key:
		&"unit_worker":
			image = _make_worker()
		&"unit_soldier":
			image = _make_soldier()
		&"bld_command_dome":
			image = _make_command_dome()
		&"bld_solar_array":
			image = _make_solar_array()
		&"bld_hls_lander":
			image = _make_hls_lander()
		&"bld_launchpad":
			image = _make_launchpad()
		&"bld_scrap_heap":
			image = _make_scrap_heap()
		&"ground_regolith_tile":
			image = _make_regolith_tile()
		&"ground_crater_decal":
			image = _make_crater_decal()
		_:
			image = _make_fallback()

	var texture: Texture2D = ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture

static func get_regolith_tile() -> Texture2D:
	return get_tex(&"ground_regolith_tile")

static func get_crater_decal() -> Texture2D:
	return get_tex(&"ground_crater_decal")

static func _make_worker() -> Image:
	var image: Image = _new_image(32, 32)
	_fill_rect(image, Rect2i(9, 12, 14, 12), WHITE)
	_fill_rect(image, Rect2i(12, 8, 8, 6), WHITE)
	_fill_rect(image, Rect2i(12, 20, 3, 4), ORANGE)
	_fill_rect(image, Rect2i(17, 20, 3, 4), ORANGE)
	_fill_rect(image, Rect2i(10, 15, 12, 3), BLUE)
	_fill_rect(image, Rect2i(11, 16, 3, 1), LIGHT_BLUE)
	_outline_alpha(image, OUTLINE)
	return image

static func _make_soldier() -> Image:
	var image: Image = _new_image(32, 32)
	_fill_rect(image, Rect2i(11, 9, 10, 6), GRAY)
	_fill_rect(image, Rect2i(9, 15, 14, 10), WHITE)
	_fill_rect(image, Rect2i(9, 23, 4, 5), DARK_GRAY)
	_fill_rect(image, Rect2i(19, 23, 4, 5), DARK_GRAY)
	_fill_rect(image, Rect2i(8, 16, 2, 6), GRAY)
	_fill_rect(image, Rect2i(22, 16, 2, 6), GRAY)
	_fill_rect(image, Rect2i(12, 11, 8, 2), BLUE)
	_outline_alpha(image, OUTLINE)
	return image

static func _make_command_dome() -> Image:
	var image: Image = _new_image(48, 48)
	_fill_rect(image, Rect2i(8, 24, 32, 14), GRAY)
	_fill_rect(image, Rect2i(17, 28, 14, 10), DARK_GRAY)
	_fill_ellipse(image, Vector2i(24, 20), Vector2i(14, 10), WHITE)
	_fill_rect(image, Rect2i(20, 16, 8, 3), LIGHT_BLUE)
	_fill_rect(image, Rect2i(10, 26, 6, 4), ORANGE)
	_fill_rect(image, Rect2i(32, 26, 6, 4), ORANGE)
	_outline_alpha(image, OUTLINE)
	return image

static func _make_solar_array() -> Image:
	var image: Image = _new_image(40, 40)
	_fill_rect(image, Rect2i(16, 20, 8, 14), GRAY)
	_fill_rect(image, Rect2i(8, 12, 24, 8), BLUE)
	for stripe: int in range(10, 31, 4):
		_fill_rect(image, Rect2i(stripe, 13, 1, 6), LIGHT_BLUE)
	_fill_rect(image, Rect2i(14, 28, 12, 4), DARK_GRAY)
	_outline_alpha(image, OUTLINE)
	return image

static func _make_hls_lander() -> Image:
	var image: Image = _new_image(56, 56)
	_fill_rect(image, Rect2i(23, 8, 10, 30), WHITE)
	_fill_rect(image, Rect2i(20, 14, 16, 6), GRAY)
	_fill_rect(image, Rect2i(20, 28, 16, 8), GRAY)
	_fill_rect(image, Rect2i(24, 18, 8, 4), LIGHT_BLUE)
	_fill_rect(image, Rect2i(16, 36, 24, 6), DARK_GRAY)
	_fill_rect(image, Rect2i(14, 42, 6, 3), ORANGE)
	_fill_rect(image, Rect2i(36, 42, 6, 3), ORANGE)
	_fill_rect(image, Rect2i(26, 42, 4, 6), GLOW)
	_outline_alpha(image, OUTLINE)
	return image

static func _make_launchpad() -> Image:
	var image: Image = _new_image(56, 40)
	_fill_rect(image, Rect2i(4, 20, 48, 14), DARK_GRAY)
	_fill_rect(image, Rect2i(10, 24, 36, 3), WHITE)
	_fill_rect(image, Rect2i(40, 8, 8, 12), GRAY)
	_outline_alpha(image, OUTLINE)
	return image

static func _make_scrap_heap() -> Image:
	var image: Image = _new_image(48, 36)
	_fill_rect(image, Rect2i(8, 15, 32, 14), DARK_GRAY)
	_fill_rect(image, Rect2i(10, 12, 10, 6), GRAY)
	_fill_rect(image, Rect2i(24, 10, 8, 7), WHITE)
	_fill_rect(image, Rect2i(30, 18, 8, 5), ORANGE)
	_outline_alpha(image, OUTLINE)
	return image

static func _make_fallback() -> Image:
	var image: Image = _new_image(16, 16)
	_fill_rect(image, Rect2i(2, 2, 12, 12), ORANGE)
	_outline_alpha(image, OUTLINE)
	return image

static func _make_regolith_tile() -> Image:
	var image: Image = _new_image(16, 16)
	_fill_rect(image, Rect2i(0, 0, 16, 16), Color(0.31, 0.31, 0.36, 1.0))
	_fill_rect(image, Rect2i(2, 2, 2, 2), Color(0.37, 0.37, 0.42, 1.0))
	_fill_rect(image, Rect2i(11, 4, 2, 2), Color(0.26, 0.26, 0.3, 1.0))
	_fill_rect(image, Rect2i(6, 10, 2, 2), Color(0.35, 0.35, 0.4, 1.0))
	_fill_rect(image, Rect2i(12, 12, 2, 2), Color(0.24, 0.24, 0.29, 1.0))
	return image

static func _make_crater_decal() -> Image:
	var image: Image = _new_image(32, 32)
	_fill_ellipse(image, Vector2i(16, 16), Vector2i(13, 9), Color(0.13, 0.13, 0.16, 0.44))
	_fill_ellipse(image, Vector2i(16, 16), Vector2i(11, 7), Color(0.37, 0.37, 0.42, 0.4))
	return image

static func _new_image(width: int, height: int) -> Image:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	return image

static func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y: int in range(rect.position.y, rect.position.y + rect.size.y):
		for x: int in range(rect.position.x, rect.position.x + rect.size.x):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			image.set_pixel(x, y, color)

static func _fill_ellipse(image: Image, center: Vector2i, radii: Vector2i, color: Color) -> void:
	for y: int in range(center.y - radii.y, center.y + radii.y + 1):
		for x: int in range(center.x - radii.x, center.x + radii.x + 1):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var dx: float = float(x - center.x) / float(maxi(radii.x, 1))
			var dy: float = float(y - center.y) / float(maxi(radii.y, 1))
			if (dx * dx) + (dy * dy) <= 1.0:
				image.set_pixel(x, y, color)

static func _outline_alpha(image: Image, outline_color: Color) -> void:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var to_outline: Array[Vector2i] = []
	for y: int in range(height):
		for x: int in range(width):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			for neighbor: Vector2i in CARDINAL_NEIGHBORS:
				var nx: int = x + neighbor.x
				var ny: int = y + neighbor.y
				if nx < 0 or ny < 0 or nx >= width or ny >= height:
					continue
				if image.get_pixel(nx, ny).a <= 0.01:
					to_outline.append(Vector2i(nx, ny))

	for pos: Vector2i in to_outline:
		if image.get_pixel(pos.x, pos.y).a <= 0.01:
			image.set_pixel(pos.x, pos.y, outline_color)
