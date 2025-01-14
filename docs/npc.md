# NPC System

## Core Components

### Controller (npc_controller.gd)
- Manages NPC behavior and state
- Handles needs and decision making
- Key properties:
  ```
  decay_rate: 1-5 units/second (randomized)
  MAX_NEED_VALUE: 100.0
  MOVEMENT_COOLDOWN: 0.75 seconds
  ```

### State Machine
```
NPCState (npc_controller.gd):
├── IDLE
│   ├── Entry: After movement unlock
│   ├── Duration: MOVEMENT_COOLDOWN (0.75s)
│   └── Exit: Timer expired or need threshold
├── MOVING_TO_ITEM
│   ├── Entry: Valid item target selected
│   ├── Duration: Until arrived
│   └── Exit: Reached item or path blocked
├── INTERACTING
│   ├── Entry: Item interaction accepted
│   ├── Duration: Item-specific
│   └── Exit: Interaction complete/cancelled
└── WANDERING
    ├── Entry: No valid items found
    ├── Duration: Until arrived
    └── Exit: Reached random destination
```

### Need System
```
Needs (npc_controller.gd):
├── hunger
├── hygiene
├── fun
└── energy
Each need:
- Range: 0-100
- Decay: 1-5 units/second
- Thresholds:
  energy <= 0: Force behavior update
  energy >= 100: Stop sitting
```

### Vision System (vision_manager.gd)
- Tracks visible items through Area2D
- Sorts items by distance to NPC
- Used for:
  ```
  - Building observations
  - Finding interaction targets
  - Pathfinding decisions
  ```

### Client System (npc_client.gd)
- Handles backend communication
- Caches NPC state
- Processes:
  ```
  - Observations
  - Action choices
  - State updates
  ```

## Key Features

### Decision Making
```
Process (npc_controller.gd):
1. Check state locks
   - Movement locked
   - Idle cooldown (0.75s)
   - Current interaction
2. Process visible items
   - Build observation text
   - Generate action options
   - Send to NPC client
3. Handle chosen action
   - move_to: Set destination
   - interact: Request interaction
   - wander: Random movement
```

### Action System
```
Available Actions:
1. Movement (for distant items)
   - Parameters: x, y coordinates
   - Generated when distance > 1
2. Interaction (for nearby items)
   - Parameters: item_name, interaction_type
   - Generated when distance <= 1
3. Wander (fallback)
   - No parameters
   - Always available
```

### Event Integration
```
Key Events:
- need_changed: Need value updates
- NpcEvents.NeedChangedEvent: System broadcast
- NpcClientEvents:
  - CreatedEvent: New NPC initialized
  - RemovedEvent: NPC cleanup
  - ActionChosenEvent: Decision made
```

## Usage

### Required Setup
```
1. Valid gameboard reference
2. Vision system configuration
3. NPC client connection
4. Need initialization
```
