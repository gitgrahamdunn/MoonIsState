extends Node
class_name Game

var current_match_id: String = ""

func start_new_match() -> void:
	DataDB.load_all()
	Sim.reset()
	current_match_id = "new_match"

func load_match(path: String) -> void:
	push_warning("load_match is not implemented yet: %s" % path)

func save_match(path: String) -> void:
	push_warning("save_match is not implemented yet: %s" % path)
