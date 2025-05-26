# Interaction System

## Core Components

### Base Interaction (interaction.gd)
```
Properties:
├── name: String
└── description: String

Signals:
├── start_request(request)
└── cancel_request(request)

Factory Methods:
├── create_start_request(npc, arguments)
└── create_cancel_request(npc, arguments)
```

### Request System (interaction_request.gd)
```
Properties:
├── interaction_name: String
├── request_type: RequestType
├── status: Status
├── npc_controller: NpcController
├── item_controller: ItemController
└── arguments: Dictionary

Enums:
├── RequestType
│   ├── START
│   └── CANCEL
└── Status
    ├── PENDING
    ├── ACCEPTED
    └── REJECTED

Signals:
├── accepted()
└── rejected(reason: String)
```

## Integration Flow

### Request Creation
```
1. Component defines interaction:
   var interaction = Interaction.new(
       "consume",
       "Consume this item"
   )

2. Register with controller:
   interactions[interaction.name] = interaction

3. Connect handlers:
   interaction.start_request.connect(_handle_start)
   interaction.cancel_request.connect(_handle_cancel)
```

### Request Processing

The general flow for starting an interaction request involves the NPC, the target Item (specifically its `ItemController`), and the relevant `Interaction` (often managed by a component on the item).

```mermaid
sequenceDiagram
    actor NPC
    participant ItemController
    participant InteractionLogic (e.g., Component)

    NPC->>InteractionLogic: Creates InteractionRequest (via interaction.create_start_request())
    InteractionLogic->>ItemController: Emits interaction.start_request(request)
    
    alt Item can handle request
        ItemController->>InteractionLogic: Validates (e.g., item not in use)
        InteractionLogic->>InteractionLogic: Further validates (e.g., component-specific conditions)
        alt All validations pass
            InteractionLogic-->>NPC: request.accept() is called
            ItemController->>ItemController: Sets current_interaction, interacting_npc
            InteractionLogic->>InteractionLogic: Sets up internal state for interaction
        else Validation fails
            InteractionLogic-->>NPC: request.reject(reason) is called
        end
    else Item cannot handle (e.g., already in use by another NPC)
        ItemController-->>NPC: request.reject(reason) is called
    end
```

**Detailed Steps (Start Flow):**

1.  **NPC Initiates:**
    *   The `NpcController` gets an `Interaction` object (e.g., from an item's available interactions).
    *   It calls `interaction.create_start_request(npc_controller, arguments)` to create an `InteractionRequest`. The request's status is initially `PENDING`.

2.  **Item Controller Receives Request:**
    *   The `Interaction` object (or the component owning it) typically emits a `start_request` signal with the `InteractionRequest`.
    *   The `ItemController` (or the relevant component listening to this signal) receives this request.

3.  **Validation & Acceptance/Rejection:**
    *   **Item-Level Validation:** The `ItemController` first performs general checks (e.g., is the item already in use by `current_interaction`?). If it fails, it calls `request.reject(reason)`.
    *   **Component-Level Validation:** If item-level checks pass, the specific component responsible for the interaction (e.g., `ConsumableComponent`) performs its own validation (e.g., `can_start()`).
    *   **Outcome:**
        *   If all validations pass, `request.accept()` is called. The `ItemController` updates its state (`current_interaction`, `interacting_npc`), and the component sets up for the interaction.
        *   If any validation fails, `request.reject(reason)` is called.

4.  **NPC Reacts:** The `NpcController` is connected to the `request.accepted` and `request.rejected` signals to proceed accordingly (e.g., log events, update state, make new decisions).

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
