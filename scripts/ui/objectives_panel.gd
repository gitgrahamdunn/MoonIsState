extends PanelContainer

const OBJ1_BASE: String = "Place Solar Array"
const OBJ2_BASE: String = "Place Regolith Collector"
const OBJ3_BASE: String = "Produce Metal (>= 50)"

@onready var obj1: Label = $VBoxContainer/Obj1Label
@onready var obj2: Label = $VBoxContainer/Obj2Label
@onready var obj3: Label = $VBoxContainer/Obj3Label

func set_state(idx: int, done: bool) -> void:
	var prefix: String = "☑ " if done else "☐ "
	if idx == 1:
		obj1.text = prefix + OBJ1_BASE
		return
	if idx == 2:
		obj2.text = prefix + OBJ2_BASE
		return
	if idx == 3:
		obj3.text = prefix + OBJ3_BASE
