# NPC Simulation Architecture

## Setup Requirements
- Godot 4.3
- Git repository access

## System Overview

### Field System
The field manages the game world:
```
Field
├── TileLayers
│   ├── Ground
│   └── Obstacles
└── Entities
    ├── NPCs
    └── Items
```

### Entity Architecture
All entities inherit from Gamepiece, implementing:
- Position and collision management
- Component-based behavior extension
- Animation system integration
- Controller logic

### Component System
Components extend entity functionality:

Item Components:
- ConsumableComponent: Modifies NPC needs when consumed
- NeedModifyingComponent: Affects NPC needs over time
- Additional components for specific interactions

Base Components:
- Animation: Handles sprite and visual state
- Controller: Manages entity behavior and state

## Implementation Reference

### Creating New Items
1. Scene Structure
   - Copy `apple.tscn` and `apple_animation.tscn` as templates
   - Rename scenes appropriately for the new item
   - Update sprite texture and frame configuration in animation scene
   - Adjust CollisionShape2D nodes in both ClickArea and CollisionArea
   - Configure item-specific properties in ItemController
   
2. Required Nodes (from apple.tscn):
```
ItemScene (Node2D)
├── Decoupler
│   └── Path2D
│       └── PathFollow2D
│           ├── CameraAnchor
│           └── GFXAnchor
├── Animation (from animation scene)
└── ItemController
    └── Components
```

3. Animation Scene Structure (from apple_animation.tscn):
```
StaticAnimation
├── AnimationPlayer
├── GFX
│   ├── Sprite
│   ├── Shadow
│   └── ClickArea
└── CollisionArea
```

4. Component Setup
```gdscript
# Example component attachment
extends "res://src/field/items/item_controller.gd"

func _ready():
    super._ready()
    var component = preload("res://src/field/items/components/your_component.gd").new()
    add_child(component)
```

### NPC Implementation
NPCs use a client-backend architecture for behavior control:

```
NpcController
    └── NpcClient (caches state, handles communication)
         └── Backend (mock or real LLM-based implementation)
```

Each NPC controller:
- Has a unique ID for backend identification
- Creates a new NPC if no ID is provided
- Communicates with the backend through the client
- Gets cleaned up when destroyed

The NPC client:
- Provides a domain-specific interface to the backend
- Caches NPC state to reduce latency
- Invalidates cache when observations are processed
- Handles conversion between domain and backend types

NPCs can:
- Process environmental inputs into observations
- Make decisions based on needs and context
- Interact with items and other NPCs
- Navigate using pathfinding

The state machine handles immediate behaviors:
```gdscript
enum NPCState {
    IDLE,
    MOVING_TO_ITEM,
    INTERACTING,
    WANDERING
}
```

While the backend handles higher-level decision making:
```gdscript
# Example observation processing
npc_client.process_observation(
    npc_id,
    "You see a chair nearby. Your energy is low (30%).",
    [
        Action.new("move_to", "Move to the chair", {"x": 10, "y": 20}),
        Action.new("interact", "Sit in the chair", {"type": "sit"})
    ]
)
```

### Event System Usage
Events handle system communication:
```gdscript
# Interaction event example
FieldEvents.emit_signal("interaction_started", {
    "source": npc,
    "target": item,
    "type": InteractionType.CONSUME
})
```

## Project Structure
```
src/
├── common/          # Core utilities
├── field/          # Game systems
│   ├── gameboard/  # Map and pathfinding
│   ├── gamepieces/ # Entity base
│   ├── items/      # Item implementations
│   └── npcs/       # NPC implementations
└── ui/             # Interface systems
```

## Technical Considerations

### Event System
- Entity events (movement, interaction)
- UI events
- System events

### Implementation Guidelines
1. Component-based functionality extension
2. Event-driven communication
3. State pattern for behavior management
4. Resource cleanup implementation
5. Accessing Controllers
   - Use Gamepiece's get_controller() method instead of direct node access
   - Cast controllers to specific types (e.g., `as NpcController`) for type safety
   - Avoid coupling UI components to specific node paths or internal gamepiece structure

### Event System Best Practices
1. Follow existing patterns in event handlers:
   ```gdscript
   FieldEvents.event_dispatched.connect(
       func(event: Event):
           if event.is_type(Event.Type.YOUR_EVENT):
               _on_your_event(event as YourEventType)
   )
   ```
2. Create event classes in appropriate event collection files (e.g., NpcEvents, NpcClientEvents)
3. Use event dispatch instead of direct signals for system-wide communication
4. Handle initial state in _ready() after connecting to events

## Future Integration
The current component and event architecture provides a foundation for LLM-based NPC control integration.

## Reference Documentation
- Component examples: `src/field/items/components/`
- Event system: `src/common/field_events.gd`
