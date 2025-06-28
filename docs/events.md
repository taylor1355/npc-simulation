# Events System

## Core Components

### Base Event (`event.gd`)
The `Event` class is the foundation for all specific event types in the system.
*   **`event_type: Type`**: Each event instance holds an `event_type` which is a value from the central `Event.Type` enum defined in this script. This enum includes all possible event type identifiers (e.g., `GAMEPIECE_CLICKED`, `NPC_NEED_CHANGED`, `INPUT_PAUSED`).
*   **`timestamp: float`**: Automatically records the Unix time when the event was created.
*   **`is_type(type: Type) -> bool`**: A utility method to check if an event instance matches a specific `Event.Type`.

### Event Bus (`EventBus` Singleton, implemented in `event_bus.gd`, extended by `field_events.gd`)
The global event bus, typically accessed via an autoload singleton named `EventBus` (which is an instance of `field_events.gd`, extending `event_bus.gd`), is responsible for dispatching all game events. The core logic resides in `event_bus.gd`.

**Key Features & Responsibilities:**
*   **Central Dispatch:** Provides a `dispatch(event: Event)` method. When called, it first emits the generic `event_dispatched(event: Event)` signal.
*   **Type-Specific Signals:** After the generic signal, `dispatch` also emits a strongly-typed signal specific to the `event.event_type`. This allows systems to listen for particular events without needing to manually check the type. Examples of specific signals include:
    *   `cell_highlighted(event: CellEvent)`
    *   `gamepiece_clicked(event: GamepieceEvents.ClickedEvent)`
    *   `npc_need_changed(event: NpcEvents.NeedChangedEvent)`
    *   `focused_gamepiece_changed(event: GamepieceEvents.FocusedEvent)`
    *   `input_paused(is_paused: bool)`
    *   (See `event_bus.gd` for the full list of specific signals.)
    *   Note: Some events, like those from `NpcClientEvents` (`NPC_CREATED`, `NPC_ACTION_CHOSEN`, etc.), might only go through the generic `event_dispatched` signal if no dedicated typed signal is defined in `event_bus.gd`'s `dispatch` method.
*   **Frame-Based Tracking:** Includes logic for tracking specific changes within a single frame, such as gamepiece cell movements.
    *   `did_gp_move_to_cell_this_frame(cell: Vector2i) -> bool`: Allows querying if any gamepiece moved to a particular cell in the current frame. This data is cleared at the end of each frame.
*   **High Process Priority:** The event bus node runs with a very high process priority to ensure its `_process` method (which clears frame-specific data) runs after other game logic.

## Event Collections

These collections define specific event classes, inheriting from `Event`, and are typically located in `src/common/events/field_events/`. Each file usually provides static factory methods (e.g., `create_clicked(gamepiece)`) for easy event instantiation.

### Gamepiece Events (`gamepiece_events.gd`)
Events related to `Gamepiece` instances:
*   **`CellChangedEvent`** (Type: `GAMEPIECE_CELL_CHANGED`): Dispatched when a gamepiece's logical grid cell changes.
    *   `gamepiece: Gamepiece` - The gamepiece that moved.
    *   `old_cell: Vector2i` - The previous cell of the gamepiece.
*   **`PathSetEvent`** (Type: `GAMEPIECE_PATH_SET`): Indicates a new path has been set for a gamepiece.
    *   `gamepiece: Gamepiece` - The gamepiece that will move.
    *   `destination_cell: Vector2i` - The target cell of the new path.
*   **`ClickedEvent`** (Type: `GAMEPIECE_CLICKED`): Fired when a gamepiece is clicked by the player.
    *   `gamepiece: Gamepiece` - The gamepiece that was clicked.
*   **`DestroyedEvent`** (Type: `GAMEPIECE_DESTROYED`): Signals that a gamepiece is being removed from the game.
    *   `gamepiece: Gamepiece` - The gamepiece being destroyed.
*   **`FocusedEvent`** (Type: `FOCUSED_GAMEPIECE_CHANGED`): Dispatched when the currently focused gamepiece changes (e.g., selected by UI).
    *   `gamepiece: Gamepiece` - The gamepiece that gained focus (can be `null`).

### NPC Events (`npc_events.gd`)
Events specific to NPC state changes:
*   **`NeedChangedEvent`** (Type: `NPC_NEED_CHANGED`): Occurs when an NPC's need value changes.
    *   `npc: Gamepiece` - The NPC whose need changed.
    *   `need_id: String` - The identifier of the need (e.g., "hunger").
    *   `new_value: float` - The updated value of the need.

### NPC Client Events (`npc_client_events.gd`)
Events related to the communication between the game and the NPC decision-making backend (client):
*   **`CreatedEvent`** (Type: `NPC_CREATED`): Signals that an NPC has been successfully registered or created in the backend.
    *   `npc_id: String` - The unique identifier of the newly created NPC.
*   **`RemovedEvent`** (Type: `NPC_REMOVED`): Signals that an NPC has been successfully removed or cleaned up in the backend.
    *   `npc_id: String` - The unique identifier of the removed NPC.
*   **`InfoReceivedEvent`** (Type: `NPC_INFO_RECEIVED`): Dispatched when information about an NPC (e.g., traits, working memory) is received from the backend.
    *   `npc_id: String` - The identifier of the NPC this information pertains to.
    *   `traits: Array[String]` - The NPC's traits.
    *   `working_memory: String` - The NPC's current working memory or state summary.
*   **`ActionChosenEvent`** (Type: `NPC_ACTION_CHOSEN`): Fired when the backend decides on an action for an NPC to perform.
    *   `npc_id: String` - The identifier of the NPC that should perform the action.
    *   `action_name: String` - The name of the chosen action (e.g., "MOVE_TO", "INTERACT_WITH").
    *   `parameters: Dictionary` - Any parameters required for the action.

### System Events (`system_events.gd`)
General system-level events:
*   **`InputPausedEvent`** (Type: `INPUT_PAUSED`): Signals a change in the input processing state (e.g., game paused).
    *   `is_paused: bool` - The new input pause state (`true` if paused, `false` otherwise).
*   **Terrain Changed** (Type: `TERRAIN_CHANGED`): Dispatched when parts of the game terrain are modified. This event uses the generic `Event` class. The dispatcher would populate its `payload` dictionary (e.g., with `affected_cells`). The `EventBus` emits a specific `terrain_changed(event: Event)` signal for this.

### Interaction Events (`interaction_events.gd`)
Events related to interaction lifecycle management, providing detailed tracking of interaction state changes:

*   **`InteractionStartedEvent`** (Type: `INTERACTION_STARTED`): Dispatched when any interaction begins.
    *   `interaction_id: String` - Unique identifier for the interaction instance
    *   `interaction_type: String` - Type of interaction ("conversation", "sit", "consume", etc.)
    *   `participants: Array[NpcController]` - All NPCs involved in the interaction

*   **`InteractionEndedEvent`** (Type: `INTERACTION_ENDED`): Dispatched when any interaction concludes.
    *   `interaction_id: String` - Unique identifier for the interaction instance
    *   `interaction_type: String` - Type of interaction that ended
    *   `participants: Array[NpcController]` - All NPCs that were involved

*   **`InteractionParticipantJoinedEvent`** (Type: `INTERACTION_PARTICIPANT_JOINED`): Dispatched when a participant joins a multi-party interaction.
    *   `interaction_id: String` - Unique identifier for the interaction
    *   `interaction_type: String` - Type of interaction being joined
    *   `participants: Array[NpcController]` - Current participants after join
    *   `joined_participant: NpcController` - The NPC that just joined

*   **`InteractionParticipantLeftEvent`** (Type: `INTERACTION_PARTICIPANT_LEFT`): Dispatched when a participant leaves a multi-party interaction.
    *   `interaction_id: String` - Unique identifier for the interaction
    *   `interaction_type: String` - Type of interaction being left
    *   `participants: Array[NpcController]` - Current participants after departure
    *   `left_participant: NpcController` - The NPC that just left

**Factory Methods:**
*   `InteractionEvents.create_interaction_started(id, type, participants)`
*   `InteractionEvents.create_interaction_ended(id, type, participants)`
*   `InteractionEvents.create_interaction_participant_joined(id, type, participants, joined)`
*   `InteractionEvents.create_interaction_participant_left(id, type, participants, left)`

### Cell Events (`cell_event.gd`)
Events related to grid cell interactions, typically from UI or selection systems:
*   **`CellEvent`** (Types: `CELL_HIGHLIGHTED`, `CELL_SELECTED`): Used for highlighting or selecting specific grid cells.
    *   `cell: Vector2i` - The coordinate of the cell affected.
    *   Created via `CellEvent.create_highlight(cell_pos)` or `CellEvent.create_select(cell_pos)`.

## Usage

### Event Dispatch
```gdscript
# Through EventBus singleton
EventBus.dispatch(
    GamepieceEvents.create_cell_changed(
        gamepiece,  # Source entity
        old_cell   # Previous position
    )
)
```

### Event Handling
```gdscript
# Generic handler with type check
EventBus.event_dispatched.connect(
    func(event: Event):
        if event.is_type(Event.Type.GAMEPIECE_CLICKED):
            handle_click(event as GamepieceEvents.ClickedEvent)
)

# Specific event handler
EventBus.gamepiece_clicked.connect(handle_click)
```

### Frame Tracking
```
Cell Change System:
- Tracks position changes per frame
- Clears on frame end
- Query API:
  did_gp_move_to_cell_this_frame()
```

### Common Patterns
```
Entity Lifecycle:
1. Creation events first
2. State change events
3. Destruction events last

State Changes:
1. Update local state
2. Dispatch change event
3. Handle side effects
```
