extends Node

# Constants
const GAMEPIECE_META_KEY = "gamepiece"  # Metadata key for storing gamepiece reference on collision areas
const GAMEPIECE_GROUP = "_GAMEPIECE_GROUP"  # Group name for all gamepieces
const GAMEPIECE_AREA_NAMES = ["CollisionArea", "VisionArea", "ClickArea"]  # Area2D node names that need gamepiece metadata

# UI Info field names - used by controllers and UI system for consistent data exchange
class UIInfoFields:
	# Common fields for all entities
	const ENTITY_TYPE = "entity_type"
	
	# NPC-specific fields
	const STATE_NAME = "state_name"
	const STATE_ENUM = "state_enum"
	const INTERACTION_NAME = "interaction_name"
	
	# Item-specific fields
	const INTERACTION_ACTIVE = "interaction_active"
	const INTERACTION_TIME = "interaction_time"
	const INTERACTING_WITH = "interacting_with"
	const INTERACTING_NPC_ID = "interacting_npc_id"
	const COMPONENT_TYPES = "component_types"
	
	# UI element identifiers
	const UI_ELEMENT = "ui_element"
	const UI_ELEMENT_ID = "ui_element_id"
	const UI_ELEMENT_TYPE = "ui_element_type"
	

## UI element types for the UI element registry
enum UIElementType {
	SPRITE,           # Main gamepiece sprite
	NAMEPLATE_EMOJI,  # Emoji showing NPC state
	NAMEPLATE_LABEL,  # NPC name label
	CLICK_AREA,       # Generic click detection area
	VISION_AREA,      # NPC vision detection area
	FLOATING_WINDOW,  # Floating UI window
}

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
