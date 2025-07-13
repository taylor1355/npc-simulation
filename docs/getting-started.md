# Getting Started

## Setup Requirements
- Godot 4.3 or later
- Git repository access
- Project cloned locally
- Optional: MCP server for AI backend (mock backend included)

## Quick Start
1. Open project in Godot
2. Open main scene (main.tscn)
3. Run the project (F5)
4. Navigate the view:
   - Right-click drag to pan camera
   - Mouse wheel to zoom in/out
   - Press Space to anchor camera to selected NPC
5. Click NPCs to view their state in UI panels
6. Watch NPCs autonomously interact with items
   - State emoji shows above each NPC: 🧍 (idle), 🚶 (moving), 🎲 (wandering), ⏳ (waiting), 🤔 (requesting)
   - During interactions: 💬 (conversation), 🍽️ (consuming), 🪑 (sitting), 🔧 (other interactions)
   - Click interaction emoji to open interaction panel (if available)
7. Press ` (backtick) to toggle debug console
   - Use "backend mock" or "backend mcp" to switch AI backends
   - Type "help" for available commands
   - Up/Down arrows navigate command history

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
The project uses a unified component architecture for both items and NPCs.

```
Component Hierarchy:
├── GamepieceComponent (Base for all controller components)
└── EntityComponent (Unified base for interactive entities)
    ├── ItemComponent (Item-specific functionality)
    │   ├── ConsumableComponent (Food, drinks)
    │   ├── SittableComponent (Chairs, benches)
    │   └── NeedModifyingComponent (Continuous effects)
    └── NpcComponent (NPC-specific functionality)
        └── ConversableComponent (Multi-party conversations)

Key Features:
├── PropertySpec System
│   ├── Type-safe configuration
│   ├── Automatic validation
│   └── Editor-friendly setup
├── InteractionFactory Pattern
│   ├── Components provide factories
│   ├── Factories create interactions
│   └── Supports multi-party interactions
└── Lifecycle Management
    ├── _component_ready() for initialization
    ├── Properties auto-configured before ready
    └── Cached interaction factories
```

## Key Concepts

### NPC Architecture
```
Three-Tier System:
├── Controller Layer (npc_controller.gd)
│   ├── State Machine (6 states)
│   │   ├── IDLE, MOVING, REQUESTING
│   │   ├── INTERACTING, WANDERING
│   │   └── WAITING
│   ├── Decision Cycle (every 3 seconds)
│   │   ├── Gather observations
│   │   ├── Send to backend
│   │   └── Execute returned action
│   └── Component Management
├── Client Layer (Backend Communication)
│   ├── McpNpcClient (GDScript facade)
│   ├── McpSdkClient (C# bridge)
│   └── McpServiceProxy (MCP SDK wrapper)
└── Backend (Decision Making)
    ├── MCP Server (production)
    └── Mock Backend (testing)

Core Systems:
├── Observation System
│   ├── CompositeObservation bundles
│   ├── Needs, Vision, Status reports
│   └── Streaming for conversations
├── Interaction System
│   ├── Bid-based requests
│   ├── Factory pattern
│   └── Multi-party support
└── Need System
    ├── HUNGER, HYGIENE, FUN, ENERGY
    ├── Decay over time
    └── Drive decisions
```

### Event System
```
EventBus Architecture:
├── Strongly-Typed Events
│   ├── Event base class
│   ├── Type enumeration
│   └── Frame tracking
├── Event Categories
│   ├── GamepieceEvents (movement, clicks)
│   ├── NpcEvents (needs, state changes)
│   ├── ConversationEvents (invites, messages)
│   ├── SystemEvents (pause, terrain)
│   └── NpcClientEvents (backend responses)
└── Usage Patterns
    ├── Direct signal connection
    ├── Generic event handling
    └── Type-based filtering
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
1. Use EntityComponent for new interactive features
2. Define properties with PropertySpec
3. Create InteractionFactory for custom interactions
4. Follow event-driven communication via EventBus
5. Implement proper cleanup in _exit_tree()
6. Use mock backend for testing

### Common Patterns
```gdscript
# Component Definition
extends ItemComponent

func _init():
    PROPERTY_SPECS["my_prop"] = PropertySpec.new(
        "my_prop", 
        TypeConverters.PropertyType.FLOAT,
        1.0
    )

func _create_interaction_factories() -> Array[InteractionFactory]:
    return [MyFactory.new(self)]

# Event Handling
EventBus.event_dispatched.connect(_on_event)

func _on_event(event: Event):
    if event.is_type(Event.Type.GAMEPIECE_CLICKED):
        var click_event = event as GamepieceEvents.ClickedEvent
        # Handle click
```

## Next Steps
1. Review system documentation
2. Examine example scenes
3. Create ItemConfig resources
4. Try placing items in editor
5. Test runtime spawning
6. Experiment with NPC behavior
