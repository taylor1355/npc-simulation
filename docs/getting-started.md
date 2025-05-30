# Getting Started

## Setup Requirements
- Godot 4.4
- Git repository access
- Project cloned locally

## Quick Start
1. Open project in Godot 4.4
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
├── Position Management (logical cell vs. visual position)
├── Animation System (via child AnimationPlayer, GFX nodes)
└── Controller Logic (delegated to a child GamepieceController)
```

### Component System
The project utilizes a component-based architecture, particularly for items, to allow for flexible and reusable behaviors.

General Gamepiece Structure:
├── `Gamepiece` (`src/field/gamepieces/gamepiece.gd`): The base entity. Visuals are often handled by child nodes like `Sprite2D` and `AnimationPlayer`.
└── `GamepieceController` (`src/field/gamepieces/controllers/gamepiece_controller.gd`): Manages the gamepiece's behavior. Specialized controllers (like `NpcController`, `ItemController`) extend this.
    └── `GamepieceComponent` (`src/field/gamepieces/controllers/gamepiece_component.gd`): Base class for components that can be attached to a `GamepieceController` to extend its functionality.

Item System Components (primarily in `src/field/items/components/`):
├── `BaseItem` (`src/field/items/base_item.tscn`, `src/field/items/base_item.gd`): The base scene/script for all items. It's a specialized `Gamepiece`.
│   └── `ItemController` (`src/field/items/item_controller.gd`): Attached to `BaseItem`, manages item-specific logic and components.
├── `ItemConfig` (Resource - `src/field/items/item_config.gd`): Defines an item's properties, including visual setup (sprite, collision) and which `ItemComponent`s it has with their configurations.
└── `ItemComponent` (`src/field/items/components/item_component.gd`): Base class for all item-specific logic modules (e.g., `ConsumableComponent`, `SittableComponent`). These extend `GamepieceComponent` and are added to the `ItemController`.

Key Characteristics of Item Components:
- Defined by scripts extending `ItemComponent`.
- Configured through `ItemConfig` and `ItemComponentConfig` resources.
- Added to an `ItemController` at runtime based on the `ItemConfig`.
- Can define custom properties (using `PropertySpec`) and `Interaction`s.
- Can be nested if a component itself instantiates other components (though less common for item components).
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
├── Client Layer (Interface to backend decision-making)
│   ├── GDScript API: `NpcClientBase` (`src/field/npcs/client/npc_client_base.gd`) defines the interface.
│   │   └── `McpNpcClient` (`src/field/npcs/client/mcp_npc_client.gd`) is the primary implementation, acting as a facade to the C# layer for MCP communication. It handles state caching & event dispatching related to client operations.
│   └── C# MCP Bridge:
│       ├── `McpSdkClient.cs` (`src/field/npcs/client/McpSdkClient.cs`): Godot Node (C#) bridging GDScript calls to the service proxy.
│       └── `McpServiceProxy.cs` (`src/field/npcs/client/McpServiceProxy.cs`): Pure C# class for direct MCP SDK interaction and connection management.
└── Backend (MCP Server)
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
