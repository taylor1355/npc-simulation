# NPC Simulation Development Guide

## Project Overview
A 2D NPC simulation game built with Godot 4.3+ where NPCs autonomously interact with items and navigate a grid-based world based on their needs. The project uses a component-based, event-driven architecture with needs-driven NPC behavior.

## Running & Testing
- Open project in Godot 4.3 or later
- Open main.tscn and run with F5
- **Controls**: Right-click drag to pan camera, mouse wheel to zoom, 'A' to anchor camera to selected NPC
- **Mock Backend**: Available for testing without MCP server (enable in NPC scenes)

## Project Structure
```
src/
├── common/          # Events, globals, shared utilities
│   ├── events/      # Event system and event types
│   └── globals.gd   # Global constants and utilities
├── field/           # Game systems
│   ├── gamepieces/  # Base entity system (movement, animation)
│   ├── gameboard/   # Grid management and pathfinding
│   ├── npcs/        # NPC behavior and decision-making
│   ├── items/       # Item system with components
│   └── interactions/# Request-response interaction system
└── ui/              # Interface components and panels
```

## Core Architecture

### Three-Tier NPC System
1. **Controller** (GDScript): Manages state machine, movement, and action execution
2. **Client** (GDScript + C#): Handles communication with decision-making backend
3. **Backend** (MCP Server or Mock): Makes decisions based on observations

### Component-Based Item System
- Items gain functionality through modular components (Consumable, Sittable, NeedModifying)
- Components use PropertySpec pattern for type-safe configuration
- Configuration is data-driven through Godot resources (ItemConfig, ItemComponentConfig)

### Event-Driven Communication
- Central EventBus dispatches all game events
- Events are strongly-typed with specific event classes
- Frame-based tracking ensures consistent timing

## Key Systems

### Grid & Movement
- **Gameboard**: Manages grid structure, cell-to-pixel conversions, boundaries
- **Pathfinder**: A* pathfinding with dynamic obstacle support
- **Gamepiece**: Base entity with decoupled logical position (grid) vs visual movement (pixels)
- Position updates tracked with frame numbers for timing consistency

### Interaction System
- Request-response pattern with explicit state management
- InteractionRequest tracks bidding process between NPCs and items
- Interaction defines the actual behavior execution
- Only one NPC can interact with an item at a time

### Need System
- Four core needs: HUNGER, HYGIENE, FUN, ENERGY (range 0-100)
- Needs decay over time at configurable rates
- Items can fill or drain needs through NeedModifyingComponent
- NPCs make decisions based on current need levels

### Vision System
- NPCs detect items within configurable vision range
- Used for decision-making observations
- Items sorted by distance for prioritization

## Physics Layers
- `0x1` (1): Gamepiece - Entity detection, movement blocking
- `0x2` (2): Terrain - Static obstacles, pathfinding blocks  
- `0x4` (4): Click - Interaction detection

## Code Style Guidelines
- **Classes**: PascalCase (e.g., GamepieceController)
- **Variables/Functions**: snake_case (e.g., current_interaction)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., MAX_NEED_VALUE)
- **Private members**: underscore prefix (e.g., _vision_manager)
- **Signals**: snake_case (e.g., need_changed)
- **Event Types**: PascalCase with "Event" suffix (e.g., GamepieceMovedEvent)

## Development Patterns

### Event Handling
```gdscript
# Direct connection for specific events
func _ready():
    EventBus.gamepiece_clicked.connect(_on_gamepiece_clicked)

# Generic connection with type checking
func _ready():
    EventBus.event_dispatched.connect(
        func(event: Event):
            if event.is_type(Event.Type.GAMEPIECE_CLICKED):
                handle_click(event as GamepieceEvents.ClickedEvent)
    )
```

### Item Creation
1. Create ItemConfig resource in editor
2. Configure sprite, collision shape, and interaction shape
3. Add ItemComponentConfig entries with properties
4. Use ItemFactory.create_item() or place directly in scene

### Component Creation
```gdscript
extends ItemComponent

func _init():
    PROPERTY_SPECS["my_property"] = PropertySpec.new(
        "my_property",
        TypeConverters.PropertyType.FLOAT,
        1.0,
        "Description for editor"
    )

var my_property: float = 1.0

func _component_ready():
    # Properties are configured, set up interactions
    _item_controller.add_interaction("my_interaction", my_interaction_func)
```

### NPC Decision Cycle
- Runs every 3 seconds (configurable DECISION_INTERVAL)
- Gathers observations: needs, visible items, current state
- Sends to backend via client layer
- Executes returned actions through state machine

## Important Patterns & Gotchas

### Resource Management
- Always implement proper cleanup in _exit_tree()
- Disconnect signals when nodes are freed
- Clear references to prevent memory leaks

### Timing & Updates
- Physics updates have one-frame delay
- Use frame-based tracking for position changes
- Event dispatch happens at very high process priority (-1000)

### Component Access
- Use `get_controller()` to access component controllers
- Controllers manage state and behavior
- Components define properties and capabilities

### Tool Scripts
- `@tool` scripts run in editor context
- Guard runtime-only code with `if not Engine.is_editor_hint()`
- Be careful with signal connections in tool scripts

## Common Tasks

### Adding New Item Type
1. Create new ItemConfig resource
2. Add appropriate component configs
3. Define interaction behaviors
4. Add to scene or use ItemFactory

### Creating New NPC Behavior
1. Extend base controller states if needed
2. Add new action types to backend
3. Update event formatter for new observations
4. Test with mock backend first

### Debugging NPCs
- Enable debug logging in NPC scenes
- Use mock backend for predictable behavior
- Check Working Memory panel in UI
- Monitor event flow with EventBus logging

## Current Technical Debt
- Inconsistent debug logging patterns
- Some terminology overloading (Event, Request, Action)
- Need better separation between interaction bidding and execution

## Testing Strategies
- Use mock backend for deterministic testing
- Test components individually with test scenes
- Verify event flow with debug logging
- Check frame-based timing with position tracking

## Performance Considerations
- NPCs make decisions every 3 seconds (not every frame)
- Vision checks use Area2D for efficiency
- Pathfinding caches results when possible
- Event system uses signals (efficient in Godot)

## Pre-Commit Workflow
Before suggesting a commit, always:
1. Run `git diff` to review all changes
2. Verify the changes match what was intended
3. Check for any unintended modifications
4. Only then suggest a commit message

## Commit Message Style
- **First line**: What changed in the fewest words possible (while still being sufficiently comprehensive)
- **Empty line**: Always leave a blank line after the header
- **Details**: Add bullet points with concrete technical details:
  - Specific files/systems affected with brief context
  - Technical reason for the change (not buzzwords)
  - Breaking changes or compatibility notes
  - Bug fixes should explain the root cause
- **Examples**:
  ```
  Refactor InteractionRequest to InteractionBid
  
  Replace InteractionRequest with InteractionBid for better separation of concerns.
  The new design uses a cleaner bidding pattern where:
  - InteractionBid is a minimal request to start/cancel interactions
  - The bid references the Interaction object directly
  - Clear bid types and status tracking
  - Updates throughout the codebase to use the new API
  ```