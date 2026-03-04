extends Control

signal build_button_clicked(building_def_id: StringName)

@onready var top_bar: PanelContainer = $TopBar
@onready var left_build_panel: PanelContainer = $LeftBuildPanel
@onready var info_panel: PanelContainer = $InfoPanel

@onready var credits_label: Label = $TopBar/TopRow/ResourceRow/CreditsLabel
@onready var regolith_label: Label = $TopBar/TopRow/ResourceRow/RegolithLabel
@onready var metal_label: Label = $TopBar/TopRow/ResourceRow/MetalLabel
@onready var power_label: Label = $TopBar/TopRow/ResourceRow/PowerLabel
@onready var oxygen_label: Label = $TopBar/TopRow/ResourceRow/OxygenLabel
@onready var time_label: Label = $TopBar/TopRow/TimeLabel
@onready var build_stamp_label: Label = $TopBar/TopRow/BuildStampLabel

@onready var selected_label: Label = $InfoPanel/InfoVBox/SelectedLabel
@onready var status_label: Label = $InfoPanel/InfoVBox/StatusLabel
@onready var stats_label: Label = $InfoPanel/InfoVBox/StatsLabel

@onready var build_hls_button: Button = $LeftBuildPanel/BuildVBox/BuildHLSButton
@onready var build_command_dome_button: Button = $LeftBuildPanel/BuildVBox/BuildCommandDomeButton
@onready var build_solar_array_button: Button = $LeftBuildPanel/BuildVBox/BuildSolarArrayButton
@onready var build_regolith_extractor_button: Button = $LeftBuildPanel/BuildVBox/BuildRegolithExtractorButton
@onready var build_refinery_button: Button = $LeftBuildPanel/BuildVBox/BuildRefineryButton

var _selected_entity_id: int = -1
var _last_displayed_second: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	left_build_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	info_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	build_hls_button.pressed.connect(func() -> void: _on_build_clicked(&"hls_lander"))
	build_command_dome_button.pressed.connect(func() -> void: _on_build_clicked(&"command_dome"))
	build_solar_array_button.pressed.connect(func() -> void: _on_build_clicked(&"solar_array"))
	build_regolith_extractor_button.pressed.connect(func() -> void: _on_build_clicked(&"regolith_extractor"))
	build_refinery_button.pressed.connect(func() -> void: _on_build_clicked(&"refinery"))

	Sim.resources_changed.connect(_on_resources_changed)
	Sim.tick_advanced.connect(_on_tick_advanced)
	Sim.entity_updated.connect(_on_entity_updated)

	_on_resources_changed(Sim.resources)
	_on_tick_advanced(Sim.tick_count)
	_show_empty_selection()

func set_build_stamp(build_stamp: String) -> void:
	build_stamp_label.text = build_stamp

func set_selected_entity(entity_id: int) -> void:
	_selected_entity_id = entity_id
	if _selected_entity_id <= 0:
		_show_empty_selection()
		return

	var entity: Dictionary = Sim.get_entity(_selected_entity_id)
	if entity.is_empty():
		_show_empty_selection()
		return

	var display_name: String = _get_entity_display_name(entity)
	selected_label.text = "Selected: %s" % display_name
	status_label.text = "Status: %s" % _get_entity_status_line(entity)
	stats_label.text = "Stats: %s" % _get_entity_stats_line(entity)

func _on_resources_changed(new_resources: Dictionary) -> void:
	credits_label.text = "$ Credits: %.2f" % float(new_resources.get(&"money", 0.0))
	regolith_label.text = "R Regolith: %.1f" % float(new_resources.get(&"regolith", 0.0))
	metal_label.text = "M Metal: %.1f" % float(new_resources.get(&"metal", 0.0))
	power_label.text = "P Power: %.1f" % float(new_resources.get(&"power", 0.0))
	oxygen_label.text = "O Oxygen: %.1f" % float(new_resources.get(&"oxygen", 0.0))

func _on_tick_advanced(new_tick_count: int) -> void:
	var seconds_total: int = int(floor(float(new_tick_count) / float(Sim.TICKS_PER_SECOND)))
	if seconds_total == _last_displayed_second:
		return
	_last_displayed_second = seconds_total

	var seconds_per_day: int = 24 * 60 * 60
	var day: int = (seconds_total / seconds_per_day) + 1
	var day_seconds: int = seconds_total % seconds_per_day
	var hours: int = day_seconds / 3600
	var minutes: int = (day_seconds % 3600) / 60
	time_label.text = "Day %d  %02d:%02d  |  Tick %d" % [day, hours, minutes, new_tick_count]

func _on_entity_updated(entity_id: int) -> void:
	if entity_id != _selected_entity_id:
		return
	set_selected_entity(_selected_entity_id)

func _on_build_clicked(building_def_id: StringName) -> void:
	print("[HUD] build clicked: %s" % String(building_def_id))
	emit_signal("build_button_clicked", building_def_id)

func _get_entity_display_name(entity: Dictionary) -> String:
	var def_id: StringName = entity.get("def_id", &"") as StringName
	var kind: StringName = entity.get("kind", &"") as StringName

	if kind == &"building":
		var building_def: BuildingDef = DataDB.get_building_def(def_id)
		if building_def != null and not building_def.display_name.is_empty():
			return building_def.display_name
	if kind == &"unit":
		var unit_def: UnitDef = DataDB.get_unit_def(def_id)
		if unit_def != null and not unit_def.display_name.is_empty():
			return unit_def.display_name

	return String(def_id)

func _get_entity_status_line(entity: Dictionary) -> String:
	if bool(entity.get("is_constructing", false)):
		var remaining: float = float(entity.get("build_remaining", 0.0))
		return "Under construction (%.1fs remaining)" % remaining

	var def_id: StringName = entity.get("def_id", &"") as StringName
	if def_id == &"solar_array":
		return "Producing: +2 Power/s"
	if def_id == &"regolith_extractor":
		return "Producing: +2 Regolith/s"
	if def_id == &"refinery":
		return "Refining regolith into metal"
	return "Idle"

func _get_entity_stats_line(entity: Dictionary) -> String:
	var kind: StringName = entity.get("kind", &"") as StringName
	var hp_text: String = ""

	if entity.has("durability"):
		hp_text = "HP %.0f" % float(entity.get("durability", 0.0))
	elif kind == &"building":
		var def_id: StringName = entity.get("def_id", &"") as StringName
		var building_def: BuildingDef = DataDB.get_building_def(def_id)
		if building_def != null:
			hp_text = "HP %d" % building_def.hp
	elif kind == &"unit":
		var unit_def_id: StringName = entity.get("def_id", &"") as StringName
		var unit_def: UnitDef = DataDB.get_unit_def(unit_def_id)
		if unit_def != null:
			hp_text = "HP %d" % unit_def.hp

	if hp_text.is_empty():
		return "--"
	return hp_text

func _show_empty_selection() -> void:
	selected_label.text = "Selected: Nothing selected"
	status_label.text = "Status: Idle"
	stats_label.text = "Stats: --"
