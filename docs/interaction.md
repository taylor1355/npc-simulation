# Interaction System

## 1. Overview

The interaction system manages all interactions between NPCs and game world objects. It is designed to be flexible and maintainable, allowing developers to easily define new ways for NPCs to interact with items and each other.

The core of the system is a generic `Interaction` class that acts as a configurable container for interaction logic. Instead of subclassing `Interaction` for every new behavior, components provide the logic directly by assigning their own methods as handlers to the interaction's lifecycle hooks. This is managed through a standardized `InteractionFactory` pattern.

### System Components
```
Interaction System
├── InteractionRegistry (common/interaction_registry.gd) - Global singleton tracking all active interactions
├── InteractionContext (interactions/interaction_context.gd) - Manages interaction state and discovery
├── NpcController (controller/npc_controller.gd) - Initiates and manages interactions via its state machine
├── Interaction (interactions/interaction.gd) - A generic class that orchestrates an interaction's lifecycle
├── InteractionFactory (interactions/interaction_factory.gd) - Creates interactions and provides metadata
├── InteractionBid (interactions/interaction_bid.gd) - Manages interaction requests with bidding process
└── Item/Npc Components (e.g., sittable_component.gd) - Define and implement the actual interaction logic
```

## 2. Core Components

### Interaction (`src/field/interactions/interaction.gd`)
The `Interaction` class is a generic, `RefCounted` object that defines a specific way an NPC can interact with an object. It manages participant lifecycles, provides event integration, and creates appropriate contexts for state management.

**Key Properties:**
*   `id: String`: Unique identifier generated automatically
*   `name: String`: A unique identifier for the interaction (e.g., "consume", "sit").
*   `description: String`: A human-readable description, which can be updated dynamically.
*   `max_participants: int`: The maximum number of NPCs that can participate (default is 1).
*   `min_participants: int`: The minimum number required to maintain the interaction
*   `requires_adjacency: bool`: If `true`, the NPC must be next to the target object to interact.
*   `needs_filled: Array[Needs.Need]`: Needs that will be increased when participating.
*   `needs_drained: Array[Needs.Need]`: Needs that will be decreased when participating.
*   `need_rates: Dictionary[Needs.Need, float]`: Per-second need change rates
*   `act_in_interaction_parameters: Dictionary[String, PropertySpec]`: Type-safe parameter specifications for actions.

**Participant Management:**
*   `participants: Array[NpcController]`: Current participants in the interaction
*   `can_add_participant(npc)`: Validates if NPC can join
*   `add_participant(npc)`: Adds NPC and triggers lifecycle events
*   `remove_participant(npc)`: Removes NPC and triggers lifecycle events

**Lifecycle Methods:**
These methods are called automatically during interaction events and dispatch corresponding `InteractionEvents`.
*   `_on_start(context)`: Called when the interaction begins, dispatches `INTERACTION_STARTED`
*   `_on_end(context)`: Called when the interaction concludes, dispatches `INTERACTION_ENDED`
*   `_on_participant_joined(participant)`: Called when a new participant is added, dispatches `INTERACTION_PARTICIPANT_JOINED`
*   `_on_participant_left(participant)`: Called when a participant leaves, dispatches `INTERACTION_PARTICIPANT_LEFT`

**Key Methods:**
*   `act_in_interaction(participant, params)`: Execute actions within the interaction with parameter validation.
*   `send_observation_to_participant(participant, observation)`: Send observations to specific participants.
*   `create_context(target_controller)`: Factory method that creates appropriate `InteractionContext` based on interaction type.
*   `get_entity_ids() -> Array[String]`: Returns entity IDs of all participants for UI highlighting.

**Signals:**
*   `act_in_interaction_received(participant, validated_parameters)`: Emitted when actions are performed
*   `participant_should_transition(participant, interaction)`: Signals participant to transition to `InteractingState`

### InteractionBid (`src/field/interactions/interaction_bid.gd`)
The `InteractionBid` class manages the request and acceptance process for starting or canceling interactions. It uses a bidding pattern where NPCs can bid to start an interaction, and the target (item or other NPC) can accept or reject the bid.

**Key Properties:**
*   `bid_type: BidType`: Either START or CANCEL
*   `bidder: NpcController`: The NPC making the bid
*   `target: GamepieceController`: The target of the interaction
*   `status: BidStatus`: PENDING, ACCEPTED, or REJECTED
*   `interaction_name: String`: Name of the interaction being bid on

**Multi-Party Support:**
The `MultiPartyBid` class extends `InteractionBid` to support interactions with multiple participants, such as conversations.

### InteractionFactory (`src/field/interactions/interaction_factory.gd`)
This is a simple interface (`RefCounted`) that standardizes the creation of `Interaction` objects. Components that provide interactions must implement a class that extends this interface.

**Key Methods:**
*   `create_interaction(context: Dictionary = {}) -> Interaction`: The core method. It is responsible for instantiating a generic `Interaction`, configuring it (e.g., setting its name and description), and assigning the component's methods to the interaction's `Callable` handlers.
*   `get_interaction_name() -> String`: Returns the unique name of the interaction.
*   `get_interaction_description() -> String`: Returns a description for the interaction.
*   `is_multi_party() -> bool`: Returns whether this factory creates multi-party interactions (default: false).
*   `get_metadata() -> Dictionary`: Returns interaction data without creating an instance. This avoids temporary object creation during discovery.

## 3. Integration Flow

The system is designed around a clear separation of responsibilities: components define the logic, factories create configured interactions, and the NPC controller drives the lifecycle.

```mermaid
sequenceDiagram
    actor NPC
    participant Component (e.g., SittableComponent)
    participant InteractionFactory
    participant InteractionBid
    participant Interaction
    participant ItemController

    NPC->>Component: Requests available interactions
    Component->>InteractionFactory: get_interaction_factories()
    InteractionFactory-->>NPC: Returns factory instance

    NPC->>InteractionBid: Creates bid to start interaction
    InteractionBid-->>ItemController: Bid submitted
    ItemController->>Component: Evaluates bid
    Component-->>InteractionBid: accept() or reject()

    alt Bid Accepted
        ItemController->>InteractionFactory: create_interaction()
        InteractionFactory->>Interaction: new()
        Note over InteractionFactory, Interaction: Assigns component methods to<br/>interaction.on_start_handler, etc.
        Interaction-->>ItemController: Returns configured Interaction
        
        ItemController->>Interaction: Calls _on_start()
        Interaction->>Component: Executes on_start_handler
        
        Note over Interaction, Component: ...Interaction is ongoing...
        
        ItemController->>Interaction: Calls _on_end()
        Interaction->>Component: Executes on_end_handler
    else Bid Rejected
        InteractionBid-->>NPC: Notifies rejection
    end
```

### Setup and Usage Example

Here is how `SittableComponent` implements the pattern.

1.  **Define the Factory:** An inner class `SitInteractionFactory` is defined inside `SittableComponent`.

2.  **Implement `create_interaction`:**
    ```gdscript
    # Inside SitInteractionFactory
    func create_interaction(context: Dictionary = {}) -> Interaction:
        var interaction = Interaction.new(
            get_interaction_name(),
            get_interaction_description(),
            true # requires_adjacency
        )
        # Assign the component's methods as handlers
        interaction.on_start_handler = sittable_component._on_sit_start
        interaction.on_end_handler = sittable_component._on_sit_end
        return interaction
    ```

3.  **Implement Component Logic:** The `SittableComponent` has the methods that will be used as handlers.
    ```gdscript
    # Inside SittableComponent
    func _on_sit_start(interaction: Interaction, context: Dictionary) -> void:
        # Logic to make the NPC sit down...
        var participant = interaction.participants[0]
        current_npc = participant
        participant.set_movement_locked(true)
        # ...and so on.

    func _on_sit_end(interaction: Interaction, context: Dictionary) -> void:
        # Logic to make the NPC stand up...
        if not current_npc or _is_exiting:
            return
        # ...and so on.
    ```

4.  **Expose the Factory:** The component provides its factory to the rest of the system.
    ```gdscript
    # Inside SittableComponent
    func get_interaction_factories() -> Array[InteractionFactory]:
        var factory = SitInteractionFactory.new()
        factory.sittable_component = self
        return [factory]
    ```

This pattern ensures that the `SittableComponent` retains full control over the logic and state associated with sitting, while the `Interaction` object remains a generic and reusable part of the core system.

## 4. Bidding Process

The interaction system uses a bidding mechanism to manage interaction requests:

1. **Bid Creation**: When an NPC wants to interact, it creates an `InteractionBid` with:
   - The interaction name (e.g., "sit", "consume")
   - The bid type (START or CANCEL)
   - The bidder (the NPC)
   - The target (the item or other NPC)

2. **Bid Evaluation**: The target's controller evaluates the bid:
   - Checks if the interaction is available
   - Verifies preconditions (e.g., adjacency, availability)
   - Accepts or rejects the bid with a reason

3. **Interaction Creation**: If the bid is accepted:
   - The controller uses the appropriate `InteractionFactory` to create an `Interaction`
   - The interaction is started with the participants
   - The lifecycle handlers are invoked

4. **Multi-Party Interactions**: For interactions involving multiple NPCs:
   - A `MultiPartyBid` is created with invited participants
   - Each invited NPC can accept or reject the invitation
   - The interaction starts only when all participants accept
   - If any participant rejects, the entire bid is rejected

This bidding system provides a clean separation between the request to interact and the actual interaction execution, allowing for proper validation and state management.

### InteractionRegistry (`src/field/common/interaction_registry.gd`)
Global singleton that tracks all active interactions. Prevents duplicate interactions and provides queries for interaction state.

**Key Responsibilities:**
- Tracks all active interactions by ID, participant, and host
- Prevents duplicate interactions through `is_participating_in()` checks
- Automatically cleans up when interactions end via EventBus
- Provides context queries for hosts

**Key Methods:**
- `register_interaction(interaction, context)`: Registers a new active interaction
- `is_participating_in(entity, interaction_type)`: Checks if entity is already in an interaction of given type
- `get_contexts_for(host)`: Returns all contexts for a host controller
- `get_participant_interactions(entity, type)`: Gets all interactions for a participant, optionally filtered by type

**Usage:**
Accessed directly as an autoload singleton:
```gdscript
# Register new interaction
InteractionRegistry.register_interaction(interaction, context)

# Check for duplicates
if InteractionRegistry.is_participating_in(npc, "conversation"):
    # NPC is already in a conversation
```

## 5. Specialized Interaction Types

### StreamingInteraction (`src/field/interactions/streaming_interaction.gd`)
A base class for interactions that need to send ongoing observations to participants.

**Key Features:**
- Extends the base `Interaction` class
- Provides infrastructure for sending observations
- Subclasses override `_generate_observation_for_participant()`
- Used for interactions with continuous updates

### InteractionContext (`src/field/interactions/interaction_context.gd`)
Manages interaction state and lifecycle for both single-party and multi-party interactions. Provides the primary interface for discovering available interactions and preventing duplicates.

**Key Properties:**
- `interaction: Interaction`: The active interaction (null if not started)
- `host: GamepieceController`: The entity hosting this context
- `context_type: ContextType`: Either ENTITY (single-party) or GROUP (multi-party)
- `is_active: bool`: Whether an interaction is currently active

**Key Methods:**
- `get_display_name() -> String`: Returns context-appropriate display name
- `get_position() -> Vector2i`: Returns relevant position (entity position or participant centroid)
- `get_entity_type() -> String`: Returns "group" for GROUP contexts, otherwise host's entity type
- `handle_cancellation()`: Routes cancellation appropriately (bid system for ENTITY, direct removal for GROUP)
- `can_start_interaction()`: Checks InteractionRegistry to prevent duplicates
- `get_context_data()`: Provides state information for observations
- `setup_completion_signals()`: Configures interaction completion detection

**Context Types:**
- `ENTITY`: Single-party interactions with items or NPCs
  - Uses bid system for cancellation
  - Provides entity-specific context data (name, type, position)
  - Sets up `interaction_finished` signal handling
- `GROUP`: Multi-party interactions like conversations
  - Uses direct participant removal for cancellation
  - Calculates centroid position of all participants
  - Provides group-specific context data (participant count, names)

**Factory Integration:**
The `Interaction.create_context(target_controller)` factory method creates an InteractionContext with the appropriate type based on `max_participants`.

### ConversationInteraction (`src/field/interactions/conversation_interaction.gd`)
Manages multi-party conversations between NPCs.

**Key Features:**
- Extends `StreamingInteraction`
- Supports 2-10 participants
- Tracks conversation history (last 5 messages)
- No adjacency requirement
- Locks movement during conversation
- Generates unique conversation IDs
- Sends `ConversationObservation` updates when messages are added

**Usage:**
Created by the `ConversableComponent` when NPCs start conversations through the multi-party bidding process. Uses `GroupInteractionContext` for state management.
