extends CanvasLayer

@export var play_chime: bool = false
@export var popup_scene: PackedScene = preload("res://scenes/ui/FloatingText.tscn")
@export var burst_scene: PackedScene = preload("res://scenes/ui/SparkleBurst.tscn")

@onready var _popup_root: Control = $PopupRoot
@onready var _burst_root: Node2D = $BurstRoot
@onready var _chime_player: AudioStreamPlayer = $ChimePlayer

func _ready() -> void:
	Sim.fx_popup.connect(_on_fx_popup)
	Sim.fx_burst.connect(_on_fx_burst)

func _on_fx_popup(world_pos: Vector2, text_value: String, kind: StringName) -> void:
	var popup: Control = popup_scene.instantiate() as Control
	if popup == null:
		return
	var screen_pos: Vector2 = _world_to_screen(world_pos)
	popup.position = screen_pos
	if popup.has_method("setup"):
		popup.call("setup", text_value, kind)
	_popup_root.add_child(popup)
	_try_play_chime()

func _on_fx_burst(world_pos: Vector2, _kind: StringName) -> void:
	var burst: Node2D = burst_scene.instantiate() as Node2D
	if burst == null:
		return
	burst.position = _world_to_screen(world_pos)
	_burst_root.add_child(burst)

func _world_to_screen(world_pos: Vector2) -> Vector2:
	var camera: Camera2D = get_tree().current_scene.get_node_or_null("World/WorldCamera") as Camera2D
	if camera == null:
		return world_pos
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var viewport_center: Vector2 = viewport_rect.size * 0.5
	var offset: Vector2 = (world_pos - camera.global_position) / camera.zoom
	return viewport_center + offset

func _try_play_chime() -> void:
	if not play_chime:
		return
	if _chime_player.stream == null:
		return
	_chime_player.play()
