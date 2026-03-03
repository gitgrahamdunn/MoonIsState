extends Node

const DEBUG_CMD: bool = false

var queue: Array[Dictionary] = []

func enqueue(command: Dictionary) -> void:
	if not command.has("type"):
		push_warning("Rejected command without required key 'type'.")
		return
	var command_type: Variant = command.get("type")
	if typeof(command_type) != TYPE_STRING and typeof(command_type) != TYPE_STRING_NAME:
		push_warning("Rejected command with invalid 'type'.")
		return
	if DEBUG_CMD:
		print("[CmdBus] enqueue ", command.get("type"))
	queue.append(command.duplicate(true))

func drain() -> Array[Dictionary]:
	var drained: Array[Dictionary] = queue
	queue = []
	if DEBUG_CMD and drained.size() > 0:
		print("[CmdBus] drain count=", drained.size())
	return drained
