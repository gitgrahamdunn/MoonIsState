extends Node
class_name CommandBus

var _queue: Array[Dictionary] = []

func enqueue(command: Dictionary) -> void:
	if not command.has("type"):
		push_warning("Rejected command without required key 'type'.")
		return
	_queue.append(command.duplicate(true))

func drain() -> Array[Dictionary]:
	var drained: Array[Dictionary] = _queue
	_queue = []
	return drained
