# Getting Started

## Setup Requirements
- Godot 4.3
- Git repository access
- Project cloned locally

## Quick Start
1. Open project in Godot 4.3
2. Open main scene (main.tscn)
3. Run the project (F5)
4. Navigate the view:
   - Right-click drag to pan camera
   - Mouse wheel to zoom in/out
   - Press A to anchor camera to selected NPC
5. Click NPCs to view their state
6. Watch them interact with items

## System Architecture

### Core Systems
```
Field (field.gd)
├── TileLayers
│   ├── Ground (TileMap)
│   └── Obstacles (TileMap)
└── Entities
    ├── NPCs (npc.tscn)
    └── Items (item.tscn)
```

### Entity System
```
Gamepiece (gamepiece.gd, gamepiece.tscn)
├── Position Management
├── Animation System
└── Controller Logic
```

### Component System
```
Base Components:
├── Animation (handles visuals)
└── Controller (manages behavior)

Item Components (components/):
├── ConsumableComponent
├── NeedModifyingComponent
└── SittableComponent
    └── NeedModifyingComponent (example of nested component)

Components can be:
- Direct children of controllers
- Children of other components
```

## Key Concepts

### NPC Architecture
```
NPC System:
├── Controller (npc_controller.gd)
├── Client (npc_client.gd)
└── Backend (mock_npc_backend.gd)

Features:
- Needs system (hunger, energy, etc.)
- Vision-based decision making
- Item interaction
- Pathfinding movement
```

### Event System
```
Event Flow (field_events.gd):
1. Local state changes
2. Event dispatched
3. System-wide updates
4. UI refresh
```

## Project Structure
```
src/
├── common/     # Shared utilities
├── field/      # Game systems
└── ui/         # Interface system

docs/           # System documentation
├── collision.md    # Physics system
├── events.md       # Event system
├── gameboard.md    # Grid system
├── gamepiece.md    # Entity base
├── items.md        # Item system
├── npc.md          # NPC system
└── ui.md           # UI system
```

## Development Guidelines

### Best Practices
1. Use get_controller() for controller access
2. Follow event-driven communication
3. Implement proper cleanup
4. Document new components

### Common Patterns
```
Component Addition:
1. Inherit from base
2. Add in _ready()
3. Connect signals
4. Handle cleanup

Event Handling:
1. Connect in _ready()
2. Type-check events
3. Cast to specific type
4. Handle appropriately
```

## Next Steps
1. Review system documentation
2. Examine example scenes
3. Try creating new items
4. Experiment with NPC behavior

## Reference
- Example items: src/field/items/
- Example NPCs: src/field/npcs/
- Documentation: docs/
