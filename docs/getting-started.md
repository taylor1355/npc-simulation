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
NPCs use placeholder state-based controllers until LLM-based control is implemented:
```gdscript
func handle_state():
    match current_state:
        NPCState.IDLE:
            process_idle()
        NPCState.INTERACTING:
            process_interaction()
        NPCState.MOVING:
            process_movement()
        NPCState.USING_ITEM:
            process_item_usage()
```

States determine NPC behavior, item interactions, and movement patterns. NPCs can:
- Process environmental inputs
- Make decisions based on needs
- Interact with items and other NPCs
- Navigate using pathfinding

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

## Future Integration
The current component and event architecture provides a foundation for LLM-based NPC control integration.

## Reference Documentation
- Component examples: `src/field/items/components/`
- Event system: `src/common/field_events.gd`
