# NPC System

## Overview
The NPC system implements real-time decision making through a three-tier architecture, verified in the source code:

- **Controller** (npc_controller.gd): Manages needs, vision, and executes actions with a decision interval of 3.0 seconds
- **Client** (npc_client.gd): Handles backend communication and state caching
- **Backend** (mock_npc_backend.gd): Makes decisions based on NPC state and events

## Core Components

### Controller (npc_controller.gd)
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

### Client (npc_client.gd)
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

### Event System (npc_event.gd)
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

### Action System (npc_response.gd)
```
Actions:
├── MOVE_TO: Path to location
├── INTERACT_WITH: Use items
├── WANDER: Random movement
├── WAIT: Stay idle
├── CONTINUE: Maintain state
└── CANCEL_INTERACTION: Stop current

Response Structure:
├── status: SUCCESS/ERROR
├── action: Action enum
└── parameters: Dictionary
```

## Communication Flow

### Decision Cycle
```
1. Controller Update (every 3.0s)
   ├── Update needs (decay)
   ├── Get visible items
   ├── Create observation event
   └── Process unhandled events

2. Backend Processing
   ├── NpcRequest(npc_id, events)
   └── Returns NpcResponse

3. Action Execution
   ├── Parse response
   ├── Execute chosen action
   └── Handle completion/errors
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
