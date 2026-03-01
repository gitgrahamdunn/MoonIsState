extends Node

var queue: Array[Dictionary] = []

func enqueue(command: Dictionary) -> void:
	if not command.has("type"):
		push_warning("Rejected command without required key 'type'.")
		return
	var command_type: Variant = command.get("type")
	if typeof(command_type) != TYPE_STRING and typeof(command_type) != TYPE_STRING_NAME:
		push_warning("Rejected command with invalid 'type'.")
		return
	print("[CmdBus] enqueue ", command.get("type"))
	queue.append(command.duplicate(true))

func drain() -> Array[Dictionary]:
	var drained: Array[Dictionary] = queue
	queue = []
	print("[CmdBus] drain count=", drained.size())
	return drained
