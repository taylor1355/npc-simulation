# NPC System

## Overview
The NPC system implements real-time decision making through a three-tier architecture that separates simulation from decision making. The system is designed to be backend-agnostic, allowing for different decision making implementations while maintaining consistent behavior and interfaces.

The system follows an event-driven architecture where NPCs observe their environment, send these observations to a decision-making backend, and execute the resulting actions. This separation allows for flexible AI implementations while keeping the core simulation logic consistent.

Core components:
- **Controller**: The main simulation layer that manages NPC state and executes actions
- **Client**: A communication layer that handles backend interaction and caches responses
- **Backend**: A pluggable decision making system (currently using a local mock implementation)

## Core Components

### Controller (npc_controller.gd)
The controller manages the NPC's physical presence in the world and its basic needs. It runs on a fixed update cycle to gather observations about the environment, manage need states, and execute actions received from the backend. This component forms the core of the simulation layer, handling all real-time aspects of NPC behavior.

```
Key Features:
├── Need System
│   ├── Needs: [hunger, hygiene, fun, energy]
│   ├── Values: 0-100 range
│   └── Decay: 1-2 units/second (randomized)
├── Decision Making
│   ├── Interval: 3.0 seconds
│   └── Event-driven updates
└── Movement Control
    ├── Pathfinding integration
    ├── Destination management
    └── Movement locking
```

The need system simulates basic requirements that drive NPC behavior. Each need decays over time, creating pressure for the NPC to seek out items that can satisfy these needs. The controller updates these values and includes them in observations sent to the backend.

### Client (npc_client.gd)
The client acts as a bridge between the controller and backend, managing communication and caching state to reduce backend load. It provides a consistent interface regardless of the backend implementation.

```
Features:
├── State Caching
│   ├── NPCState class
│   │   ├── traits: Array[String]
│   │   └── working_memory: String
│   └── Cache invalidation on updates
├── Backend Interface
│   ├── create_npc(id, traits, memory)
│   ├── process_observation(id, events)
│   ├── cleanup_npc(id)
│   └── get_npc_info(id)
└── Event Dispatching
    ├── NPC creation/removal
    ├── Action decisions
    └── Error handling
```

The client maintains a local cache of NPC state and provides methods for lifecycle management. It handles the conversion between the simulation's event-based model and the backend's request-response pattern.

### Event System (npc_event.gd)
Events form the core communication mechanism within the NPC system, providing a standardized way to track state changes and trigger responses. This event-driven approach enables loose coupling between components and provides a clear audit trail of system behavior.

```
Event Types:
├── Interaction Events
│   ├── REQUEST_PENDING
│   ├── REQUEST_REJECTED
│   ├── STARTED
│   ├── CANCELED
│   └── FINISHED
├── OBSERVATION
└── ERROR

Event Structure:
├── timestamp: float (unix time)
├── type: Type (enum)
└── payload: Dictionary
```

Events are used to track interaction lifecycles and capture environmental observations. The payload structure varies by event type but always includes relevant context for decision making.

### Action System (npc_response.gd)
Actions represent the decisions made by the backend, translated into concrete behaviors the controller can execute. Each action type defines a specific operation with its own parameters and validation rules, providing a clear interface between decision making and execution.

```
Actions:
├── MOVE_TO: Path to location
├── INTERACT_WITH: Interact with an item
├── WANDER: Random movement
├── WAIT: Stay idle
├── CONTINUE: Maintain state
└── CANCEL_INTERACTION: Stop current interaction

Response Structure:
├── status: SUCCESS/ERROR
├── action: Action enum
└── parameters: Dictionary
```

The controller executes these actions through the appropriate systems (movement, interaction, etc). Failed actions trigger new observation events to get updated decisions.

## Communication Flow
### Decision Cycle
The decision cycle runs continuously, with the controller gathering observations and executing actions. The client manages the flow of information between components and ensures proper error handling.

```
Controller                 Client                    Backend
    │                        │                         │
    ├─ Update needs ─────────┤                         │
    │  (decay over time)     │                         │
    │                        │                         │
    ├─ Get visible items ────┤                         │
    │  (via vision system)   │                         │
    │                        │                         │
    ├─ Create observation ───┼─── Forward request ────>│
    │  (needs + items)       │                         │
    │                        │                         │
    │                        │<── Return decision ─────┤
    │                        │    (action to take)     │
    │                        │                         │
    │<── Return action ──────┤                         │
    │                        │                         │
    ├─ Execute action ───────┤                         │
    │  (move/interact)       │                         │
    │                        │                         │
    ├─ Handle result ────────┼─── Report result ──────>│
    │  (success/failure)     │                         │
    v                        v                         v
```


### Interaction Flow
```
Start Interaction:
1. Controller creates request
2. Item validates request
3. If accepted:
   ├── Set current_interaction
   ├── Connect completion handler
   └── Log STARTED event
4. If rejected:
   ├── Log REJECTED event
   └── Trigger new decision

Cancel Interaction:
1. Create cancel request
2. If accepted:
   ├── Log CANCELED event
   ├── Clear interaction state
   └── Trigger new decision
3. If rejected:
   └── Log rejection reason
```

Interactions follow a request-response pattern with explicit state transitions. This ensures proper cleanup and maintains consistency between the NPC and item states.

## Backend Interface
The backend system is designed to be replaceable, requiring only a few key capabilities:

1. NPC Creation
   - Accept traits and initial memory
   - Return unique identifier

2. Observation Processing
   - Handle environment observations
   - Process interaction events
   - Return action decisions

3. State Management
   - Maintain NPC state
   - Handle cleanup on removal

The mock_backend/ directory contains a reference implementation using a state machine pattern, but this will eventually be replaced with a server-based implementation.
