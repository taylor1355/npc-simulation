# Interaction System

## Core Components

### Base Interaction (`src/field/interactions/interaction.gd`)
The `Interaction` class (extends `RefCounted`) defines a specific way an NPC can interact with an item. Instances of this class are typically created and managed by `ItemComponent`s and registered with the `ItemController`.

**Key Properties:**
*   `name: String`: A unique identifier for the interaction (e.g., "consume", "sit").
*   `description: String`: A human-readable description (e.g., "Consume this item", "Sit on the chair").
*   `needs_filled: Array[Needs.Need]`: An array of `Needs.Need` enums that this interaction helps satisfy.
*   `needs_drained: Array[Needs.Need]`: An array of `Needs.Need` enums that this interaction depletes.

**Key Signals:**
*   `start_request(request: InteractionRequest)`: Emitted when an NPC attempts to start this interaction. Connected to by the component that implements the interaction logic.
*   `cancel_request(request: InteractionRequest)`: Emitted when an NPC attempts to cancel this interaction.

**Factory Methods:**
*   `create_start_request(npc: NpcController, arguments: Dictionary = {}) -> InteractionRequest`: Creates an `InteractionRequest` of type `START`.
*   `create_cancel_request(npc: NpcController, arguments: Dictionary = {}) -> InteractionRequest`: Creates an `InteractionRequest` of type `CANCEL`.

**Serialization:**
*   `to_dict() -> Dictionary`: Returns a dictionary representation of the interaction, including its name, description, and stringified need effects, useful for backend communication.

### Request System (`src/field/interactions/interaction_request.gd`)
The `InteractionRequest` class (extends `RefCounted`) represents an NPC's attempt to start or cancel an interaction with an item.

**Key Properties:**
*   `interaction_name: String`: The name of the interaction being requested.
*   `request_type: RequestType`: An enum (`START` or `CANCEL`).
*   `status: Status`: An enum (`PENDING`, `ACCEPTED`, or `REJECTED`), initialized to `PENDING`.
*   `npc_controller: NpcController`: The NPC making the request.
*   `item_controller: ItemController`: The target item of the request. This is typically assigned by the `ItemController` when it begins processing the request, not during the `InteractionRequest`'s initialization.
*   `arguments: Dictionary[String, Variant]`: Any additional data or parameters for the request.

**Key Signals:**
*   `accepted()`: Emitted when the request is accepted (by calling `request.accept()`).
*   `rejected(reason: String)`: Emitted when the request is rejected (by calling `request.reject(reason)`).

**Methods:**
*   `accept()`: Sets status to `ACCEPTED` and emits `accepted`.
*   `reject(reason: String)`: Sets status to `REJECTED` and emits `rejected`.

## Integration Flow

### Request Creation
An `ItemComponent` typically defines and registers `Interaction` objects with its parent `ItemController` during its setup.
```gdscript
# Example within an ItemComponent's _setup() or _ready() method:
func _component_ready(): # Or _setup() if ItemComponent uses that
    var interaction = Interaction.new(
        "consume",                                 # Interaction name
        "Consume this item to satisfy hunger.",    # Description
        [Needs.Need.HUNGER],                       # Needs filled
        []                                         # Needs drained (optional, defaults to empty)
    )
    
    # Register with the ItemController (controller is a reference to ItemController)
    controller.interactions[interaction.name] = interaction 
    
    # Connect component's handler to the interaction's signal
    interaction.start_request.connect(_on_my_interaction_start)
    interaction.cancel_request.connect(_on_my_interaction_cancel)

func _on_my_interaction_start(request: InteractionRequest):
    # Component-specific logic to handle start request
    if _can_start_consuming(request):
        request.accept()
        # ... start consuming logic ...
    else:
        request.reject("Cannot consume right now.")
```

### Request Processing
The general flow for an NPC starting an interaction with an item:

```mermaid
sequenceDiagram
    actor NPC
    participant ItemController
    participant InteractionLogic (e.g., Component)

    NPC->>ItemController: Calls item_controller.request_interaction(InteractionRequest)
    Note over NPC,ItemController: NPC creates InteractionRequest first using Interaction.create_start_request()

    ItemController->>ItemController: Initial validation (e.g., not busy?)
    alt Initial validation fails (Item busy)
        ItemController-->>NPC: request.reject(reason) is called directly
    else Initial validation passes
        Note over ItemController: ItemController assigns request.item_controller = self
        Note over ItemController: ItemController connects internal handler to request.accepted signal
        ItemController->>InteractionLogic: Emits specific_interaction.start_request(request)
        
        InteractionLogic->>InteractionLogic: Component-specific validation (e.g., can_start_interaction?)
        alt Component validation passes
            InteractionLogic-->>NPC: request.accept() is called
            Note over InteractionLogic, NPC: This triggers ItemController's internal accepted handler AND NPC's accepted handler
            InteractionLogic->>InteractionLogic: Component sets up its internal state for interaction
        else Component validation fails
            InteractionLogic-->>NPC: request.reject(reason) is called
            Note over InteractionLogic, NPC: This triggers NPC's rejected handler
        end
    end
```

**Detailed Steps (Start Flow):**

1.  **NPC Initiates:**
    *   The `NpcController` (or one of its states) identifies a target `ItemController` and the desired `Interaction` (e.g., by accessing `item_controller.interactions["interaction_name"]`).
    *   It creates an `InteractionRequest` using `interaction.create_start_request(npc_controller, arguments)`. The request's status is initially `PENDING`.
    *   The NPC logic then calls `item_controller.request_interaction(the_new_request)`.

2.  **ItemController Processes Initial Request (`ItemController.request_interaction` method):**
    *   The `ItemController` receives the `InteractionRequest`.
    *   It performs item-level validation:
        *   Checks if an `current_interaction` is already in progress. If so, it calls `request.reject("An interaction is already in progress")` and the flow stops here for this request.
        *   It assigns `request.item_controller = self` so the request knows its target item.
        *   It retrieves the specific `Interaction` object from its own `interactions` dictionary using `request.interaction_name`. If not found, it calls `request.reject("Interaction not found")`.
    *   If these initial checks pass, the `ItemController` connects an internal lambda function to the `request.accepted` signal. This lambda is responsible for setting `item_controller.current_interaction = interaction` and `item_controller.interacting_npc = request.npc_controller` if the request is ultimately accepted by the component.
    *   Then, the `ItemController` emits the specific `Interaction` object's signal: `interaction.start_request.emit(request)`. This delegates the detailed validation and logic to the `ItemComponent` that defined and handles this particular interaction.

3.  **Component Handles Interaction Logic & Validation:**
    *   The `ItemComponent` responsible for this `interaction` (which previously connected its own handler, e.g., `_on_consume_start`, to this specific `interaction.start_request` signal) receives the signal along with the `InteractionRequest`.
    *   This component's handler performs its specific validation logic (e.g., checking if the NPC meets certain criteria, if the component has resources, etc.).
    *   Based on its validation:
        *   If valid, it calls `request.accept()`.
        *   If invalid, it calls `request.reject(reason_string)`.

4.  **Outcome & NPC Reaction:**
    *   If `request.accept()` was called by the component:
        *   The `request.accepted` signal is emitted.
        *   The `ItemController`'s internal handler (connected in Step 2) executes, updating `current_interaction` and `interacting_npc` on the `ItemController`.
        *   The `NpcController` (which should also have connected its own handlers to `request.accepted`) is notified and proceeds with the interaction (e.g., moves to the item, updates its internal state, logs an `NpcEvent.INTERACTION_STARTED`).
    *   If `request.reject()` was called (either by the `ItemController` in Step 2 or by the component in Step 3):
        *   The `request.rejected` signal is emitted with a reason.
        *   The `NpcController` (connected to `request.rejected`) handles the rejection (e.g., logs an `NpcEvent.INTERACTION_REQUEST_REJECTED`, makes a new decision).

**Cancel Flow:**
The cancellation flow is similar:
1.  NPC (or system) creates a `cancel_request`.
2.  The `Interaction` (or its component) and `ItemController` validate if cancellation is possible/appropriate.
3.  If accepted, state is cleaned up. If rejected, the reason is typically logged.

### State Management
```
Item Controller:
├── interactions: Dictionary
├── current_interaction: Interaction
├── interacting_npc: NpcController
└── interaction_time: float

Component:
├── Tracks specific state
├── Handles validation
├── Manages cleanup
└── Emits completion
```
