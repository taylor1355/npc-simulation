# Interaction System

## 1. Overview

The interaction system manages all interactions between NPCs and game world objects. It is designed to be flexible and maintainable, allowing developers to easily define new ways for NPCs to interact with items and each other.

The core of the system is a generic `Interaction` class that acts as a configurable container for interaction logic. Instead of subclassing `Interaction` for every new behavior, components provide the logic directly by assigning their own methods as handlers to the interaction's lifecycle hooks. This is managed through a standardized `InteractionFactory` pattern.

### System Components
```
Interaction System
├── NpcController (controller/npc_controller.gd) - Initiates and manages interactions via its state machine.
├── Interaction (interactions/interaction.gd) - A generic class that orchestrates an interaction's lifecycle.
├── InteractionFactory (interactions/interaction_factory.gd) - A factory interface for creating configured Interaction instances.
├── InteractionBid (interactions/interaction_bid.gd) - Manages interaction requests with bidding process.
└── Item/Npc Components (e.g., sittable_component.gd) - Define and implement the actual interaction logic.
```

## 2. Core Components

### Interaction (`src/field/interactions/interaction.gd`)
The `Interaction` class is a generic, `RefCounted` object that defines a specific way an NPC can interact with an object. It does not contain behavior-specific logic itself; instead, it orchestrates the interaction lifecycle by invoking `Callable` handlers provided by the component that created it.

**Key Properties:**
*   `name: String`: A unique identifier for the interaction (e.g., "consume", "sit").
*   `description: String`: A human-readable description, which can be updated dynamically.
*   `max_participants: int`: The maximum number of NPCs that can participate (default is 1).
*   `requires_adjacency: bool`: If `true`, the NPC must be next to the target object to interact.
*   `needs_filled: Dictionary[String, float]`: Needs that will be filled when participating.
*   `needs_drained: Dictionary[String, float]`: Needs that will be drained when participating.
*   `action_parameter_specs: Dictionary[String, PropertySpec]`: Type-safe parameter specifications for actions.

**Lifecycle Handlers (`Callable`):**
These are the core of the new system. A component assigns its own methods to these handlers to inject logic into the interaction's lifecycle.
*   `on_start_handler`: Called when the interaction begins.
*   `on_end_handler`: Called when the interaction concludes.
*   `on_participant_joined_handler`: Called when a new participant is added.
*   `on_participant_left_handler`: Called when a participant leaves.

**Key Methods:**
*   `act_in_interaction(action_name: String, params: Dictionary)`: Execute actions within the interaction with parameter validation.
*   `send_observation(observation: Observation)`: Send observations to all participants (for streaming interactions).

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

## 5. Specialized Interaction Types

### StreamingInteraction (`src/field/interactions/streaming_interaction.gd`)
A base class for interactions that need to send ongoing observations to participants.

**Key Features:**
- Extends the base `Interaction` class
- Provides infrastructure for sending observations
- Subclasses override `_generate_observation_for_participant()`
- Used for interactions with continuous updates

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
Created by the `ConversableComponent` when NPCs start conversations through the multi-party bidding process.
