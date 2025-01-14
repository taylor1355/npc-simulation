class_name Event extends RefCounted

## Base class for all game events
## Provides common functionality for the event system

enum Type {
	CELL_HIGHLIGHTED,
	CELL_SELECTED,
	GAMEPIECE_CELL_CHANGED,
	GAMEPIECE_PATH_SET,
	GAMEPIECE_CLICKED,
	GAMEPIECE_DESTROYED,
	NPC_NEED_CHANGED,
	NPC_CREATED,
	NPC_REMOVED,
	NPC_INFO_RECEIVED,
	NPC_ACTION_CHOSEN,
	FOCUSED_GAMEPIECE_CHANGED,
	TERRAIN_CHANGED,
	INPUT_PAUSED
}

var event_type: Type
var timestamp: float

func _init(type: Type) -> void:
	event_type = type
	timestamp = Time.get_unix_time_from_system()

## Helper function to check event type
func is_type(type: Type) -> bool:
	return event_type == type
