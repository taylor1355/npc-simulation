class_name SystemEvents extends RefCounted

## Collection of system-related event classes

class InputPausedEvent extends Event:
	var is_paused: bool
	
	func _init(paused: bool) -> void:
		super(Type.INPUT_PAUSED)
		is_paused = paused

class BackendSwitchedEvent extends Event:
	var backend_type: NpcClientFactory.BackendType
	
	func _init(type: NpcClientFactory.BackendType) -> void:
		super(Type.BACKEND_SWITCHED)
		backend_type = type

## Static factory methods
static func create_input_paused(paused: bool) -> InputPausedEvent:
	return InputPausedEvent.new(paused)

static func create_backend_switched(type: NpcClientFactory.BackendType) -> BackendSwitchedEvent:
	return BackendSwitchedEvent.new(type)
