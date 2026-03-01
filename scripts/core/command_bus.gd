extends Node
class_name CommandBus

var queue: Array[Dictionary] = []

func enqueue(command: Dictionary) -> void:
	if not command.has("type"):
		push_warning("Rejected command without required key 'type'.")
		return
	queue.append(command.duplicate(true))

func drain() -> Array[Dictionary]:
	var drained: Array[Dictionary] = queue
	queue = []
	return drained
