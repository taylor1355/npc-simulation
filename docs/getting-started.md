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
    └── Items (base_item.tscn + configs)
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

Item System:
├── BaseItem (base_item.tscn)
├── ItemConfig (Resource)
└── Components
    ├── ConsumableComponent
    ├── NeedModifyingComponent
    └── SittableComponent

Components:
- Configured through resources
- Added at runtime
- Can be nested
```

## Key Concepts

### NPC Architecture
```
NPC System:
├── Controller (npc_controller.gd)
│   ├── Recurring decision cycle
│   ├── Need system
│   │   ├── Types: hunger, hygiene, fun, energy
│   │   ├── Value tracking
│   │   └── Automatic decay
│   └── Vision-based decisions
├── Client (npc_client.gd)
│   ├── Backend communication
│   ├── State caching
│   └── Event dispatching
└── Backend (mock_npc_backend.gd)
    └── Decision making

Features:
├── Needs Management
│   ├── Configurable decay
│   └── Component-based updates
├── Vision System
│   ├── Item detection
│   └── Distance sorting
├── Interaction System
│   ├── Request validation
│   ├── State tracking
│   └── Event logging
└── Movement System
    ├── Pathfinding
    ├── Destination management
    └── Movement locking
```

### Event System
```
Event Flow:
├── NPC Events
│   ├── Interaction lifecycle
│   │   ├── REQUEST_PENDING
│   │   ├── REQUEST_REJECTED
│   │   ├── STARTED
│   │   ├── CANCELED
│   │   └── FINISHED
│   └── OBSERVATION
├── Response System
│   ├── SUCCESS/ERROR status
│   └── Action types:
│       ├── MOVE_TO
│       ├── INTERACT_WITH
│       ├── WANDER
│       ├── WAIT
│       ├── CONTINUE
│       └── CANCEL_INTERACTION
└── Field Events
    ├── Global dispatch
    └── System-wide updates
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
Item Creation:
1. Create ItemConfig resource
2. Configure properties
3. Add component configs
4. Place in editor or spawn at runtime

Event Handling:
1. Connect in _ready()
2. Type-check events
3. Cast to specific type
4. Handle appropriately
```

## Next Steps
1. Review system documentation
2. Examine example scenes
3. Create ItemConfig resources
4. Try placing items in editor
5. Test runtime spawning
6. Experiment with NPC behavior
