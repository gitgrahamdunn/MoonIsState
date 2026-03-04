extends Node

@export var panel_path: NodePath

var _panel: Node = null
var _accum: float = 0.0

func _ready() -> void:
	_panel = get_node_or_null(panel_path)
	if _panel == null:
		push_error("ObjectivesController: panel not found at " + str(panel_path))

func _process(delta: float) -> void:
	if _panel == null:
		return
	_accum += delta
	if _accum < 1.0:
		return
	_accum = 0.0

	var placed_solar: bool = _has_def_id(&"solar_array")
	var placed_regolith: bool = _has_def_id(&"regolith_collector")
	var metal_ok: bool = float(Sim.resources.get(&"metal", 0.0)) >= 50.0

	_panel.call("set_state", 1, placed_solar)
	_panel.call("set_state", 2, placed_regolith)
	_panel.call("set_state", 3, metal_ok)

func _has_def_id(def_id: StringName) -> bool:
	for idv: Variant in Sim.entities.keys():
		var e: Dictionary = Sim.entities[int(idv)] as Dictionary
		var did: StringName = e.get("def_id", &"") as StringName
		if did == def_id:
			return true
	return false
