class_name SystemEvents extends RefCounted

## Collection of system-related event classes

class InputPausedEvent extends Event:
	var is_paused: bool
	
	func _init(paused: bool) -> void:
		super(Type.INPUT_PAUSED)
		is_paused = paused

## Static factory methods
static func create_input_paused(paused: bool) -> InputPausedEvent:
	return InputPausedEvent.new(paused)
