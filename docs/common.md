# Common Systems

## ID Generation (`src/common/id_generator.gd`)

The `IdGenerator` class provides consistent ID generation across the system. All IDs are UUID-based with type prefixes for clarity.

**Available Generators:**
- `generate_entity_id()` - For gamepieces (NPCs and items)
- `generate_interaction_id()` - For interaction instances
- `generate_conversation_id()` - For conversation interactions specifically
- `generate_bid_id()` - For interaction bids
- `generate_ui_element_id()` - For UI element registration
- `generate_interaction_panel_id(interaction_id)` - For interaction-specific UI panels

**Usage:**
```gdscript
# Entity creation
entity_id = IdGenerator.generate_entity_id()  # "entity_<uuid>"

# UI panel association
window_id = IdGenerator.generate_interaction_panel_id(interaction.id)
```

## Entity Registry (`src/common/entity_registry.gd`)

The `EntityRegistry` singleton provides safe entity lookups by ID, preventing "freed instance" errors.

**Key Features:**
- Tracks all active gamepiece controllers by entity ID
- Automatic cleanup when entities are destroyed
- Safe null returns for freed entities

**Core Methods:**
- `register(controller)` - Register a gamepiece controller
- `get_entity(entity_id)` - Get controller by ID (returns null if freed)
- `entity_exists(entity_id)` - Check if entity is still valid

**Usage:**
```gdscript
# Safe entity lookup
var target = EntityRegistry.get_entity(target_id)
if target:
    # Entity is valid and can be used
    target.do_something()
```

## Global Constants (`src/common/globals.gd`)

The `Globals` singleton provides system-wide constants and enumerations.

### Core Constants
- `GAMEPIECE_META_KEY = "gamepiece"` - Metadata key for storing gamepiece references
- `GAMEPIECE_GROUP = "_GAMEPIECE_GROUP"` - Group name for all gamepieces
- `GAMEPIECE_AREA_NAMES = ["CollisionArea", "VisionArea", "ClickArea"]` - Area2D names that receive gamepiece metadata

### UI Info Fields
The `UIInfoFields` class defines standard field names for UI data exchange:

**Common Fields:**
- `ENTITY_TYPE` - Entity type identifier ("npc", "item")

**NPC Fields:**
- `STATE_NAME` - Current state name
- `STATE_ENUM` - State enum value
- `INTERACTION_NAME` - Active interaction name

**Item Fields:**
- `INTERACTION_ACTIVE` - Whether item is in use
- `INTERACTION_TIME` - Duration of interaction
- `INTERACTING_WITH` - Entity being interacted with
- `COMPONENT_TYPES` - List of component type names

**UI Element Fields:**
- `UI_ELEMENT_ID` - Unique UI element identifier
- `UI_ELEMENT_TYPE` - Type enum value

### UI Element Types
```gdscript
enum UIElementType {
    SPRITE,           # Main gamepiece sprite
    NAMEPLATE_EMOJI,  # Emoji showing NPC state
    NAMEPLATE_LABEL,  # NPC name label
    CLICK_AREA,       # Generic click detection area
    VISION_AREA,      # NPC vision detection area
    FLOATING_WINDOW,  # Floating UI window
}
```

## Event Bus (`src/common/events/event_bus.gd`)

The centralized event system uses the `EventBus` singleton for decoupled communication between game systems. It provides strongly-typed events and high-priority processing to ensure events are handled before other systems update.

See [Events Documentation](events.md) for detailed usage and event types.

## Interaction Registry (`src/common/interaction_registry.gd`)

Global singleton tracking all active interactions in the system. It prevents duplicate interactions, enables queries about who is interacting with whom, and manages interaction lifecycle.

See [Interaction Documentation](interaction.md) for details.

## UI Registry (`src/common/ui_registry.gd`)

Singleton coordinating UI functionality through several subsystems:

- **BehaviorRegistry**: Maps UI triggers (hover, click, etc.) to behavioral responses
- **UIStateTracker**: Tracks hover, focus, and selection states for UI elements
- **PanelProvider**: Interface for components to provide their UI panels

The registry manages UI element lifecycle, behavior execution, and state synchronization across the UI system.

See [UI Documentation](ui/README.md) for detailed architecture and usage.