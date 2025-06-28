extends Node

# Constants
const GAMEPIECE_META_KEY = "gamepiece"  # Metadata key for storing gamepiece reference on collision areas
const GAMEPIECE_GROUP = "_GAMEPIECE_GROUP"  # Group name for all gamepieces

var focused_gamepiece: Gamepiece = null
var npc_client: NpcClientBase = null

func _ready() -> void:
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.FOCUSED_GAMEPIECE_CHANGED):
				_on_focused_gamepiece_changed(event as GamepieceEvents.FocusedEvent)
	)

func _on_focused_gamepiece_changed(event: GamepieceEvents.FocusedEvent) -> void:
	focused_gamepiece = event.gamepiece
