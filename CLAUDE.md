# NPC Simulation Development Guide

## Project Overview
A 2D NPC simulation game built with Godot 4.3+ where NPCs autonomously interact with items and navigate a grid-based world based on their needs. The project uses a component-based, event-driven architecture with needs-driven NPC behavior.

## Running & Testing
- Open project in Godot 4.3 or later
- Open main.tscn and run with F5
- **Controls**: Right-click drag to pan camera, mouse wheel to zoom, 'A' to anchor camera to selected NPC
- **Mock Backend**: Available for testing without MCP server (enable in NPC scenes)
- **Debug Console**: Press ` (backtick) to toggle debug console for runtime backend switching

## Project Structure
```
src/
├── common/          # Events, globals, shared utilities
│   ├── events/      # Event system and event types
│   └── globals.gd   # Global constants and utilities
├── field/           # Game systems
│   ├── gamepieces/  # Base entity system (movement, animation)
│   │   └── components/ # EntityComponent base for items and NPCs
│   ├── gameboard/   # Grid management and pathfinding
│   ├── npcs/        # NPC behavior and decision-making
│   │   ├── components/  # NPC-specific components (Conversable)
│   │   ├── controller/  # State machine and states
│   │   ├── client/      # Backend communication layer
│   │   └── observations/# Structured data for decision-making
│   ├── items/       # Item system with components
│   └── interactions/# Bid-based interaction system with factories
└── ui/              # Interface components and panels
```

## Core Architecture

### Three-Tier NPC System
1. **Controller** (GDScript): Manages state machine, movement, and action execution
2. **Client** (GDScript + C#): Handles communication with decision-making backend
3. **Backend** (MCP Server or Mock): Makes decisions based on observations

### Component-Based System
- **EntityComponent**: Base class for all components (items and NPCs)
  - Unified property configuration via PropertySpec
  - Automatic type conversion and validation
  - Interaction factory support
- **Item Components**: Consumable, Sittable, NeedModifying
- **NPC Components**: ConversableComponent for multi-party conversations
- Configuration is data-driven through Godot resources

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
- **Bid-based pattern**: InteractionBid represents requests, Interaction executes behavior
- **Factory pattern**: Components create interactions via InteractionFactory
- **Multi-party support**: MultiPartyBid for conversations and group interactions
- **Streaming interactions**: Base class for interactions with ongoing observations
- **Lifecycle hooks**: _on_start(), _on_end(), _on_participant_joined/left()
- Only one NPC can interact with an item at a time (except multi-party interactions)

### Need System
- Four core needs: HUNGER, HYGIENE, FUN, ENERGY (range 0-100)
- Needs decay over time at configurable rates
- Items can fill or drain needs through NeedModifyingComponent
- NPCs make decisions based on current need levels

### Vision System
- NPCs detect items within configurable vision range
- Used for decision-making observations
- Items sorted by distance for prioritization

### Conversation System
- **ConversableComponent**: Enables multi-party conversations (2-10 participants)
- **MultiPartyBid**: Handles invitation protocol with timeout mechanism
- **ConversationInteraction**: Extends StreamingInteraction for message history
- **State management**: Dedicated CONVERSING state in NPC controller
- **Actions**: start_conversation, send_message, leave_conversation
- **Constraints**: Movement locked during conversations, no adjacency requirement
- **Events**: Dedicated conversation events for invitation, messages, and termination

### Observation System
- **Structured data** for NPC decision-making backend
- **CompositeObservation**: Container for bundling multiple observations
- **Core observations**:
  - NeedsObservation: Current need levels as percentages
  - VisionObservation: Visible entities with available interactions
  - StatusObservation: Position, state, current interaction
  - ConversationObservation: Conversation history and participants
- **Event observations**: Interaction requests, rejections, updates
- **Streaming support**: For ongoing interactions like conversations

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
- **Comments**: Focus on what the code does and why, not implementation history or alternatives considered
  - Avoid overly specific context-dependent comments that won't make sense later
  - Write comments that explain the "why" for future maintainers, not current debugging context
- **Control Flow**: Follow Zen of Python principles - "Flat is better than nested"
  - Use early returns instead of deep nesting
  - Guard clauses at function start
  - Invert conditions to reduce indentation levels

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

#### Item Components
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
    pass

func _create_interaction_factories() -> Array[InteractionFactory]:
    # Return array of factories that create interactions for this component
    return [MyInteractionFactory.new(self)]
```

#### NPC Components
```gdscript
extends NpcComponent

func _init():
    PROPERTY_SPECS["conversation_range"] = PropertySpec.new(
        "conversation_range",
        TypeConverters.PropertyType.FLOAT,
        5.0,
        "Range for conversation detection"
    )

var conversation_range: float = 5.0

func _component_ready():
    # Set up NPC-specific functionality
    var npc_controller = get_npc_controller()
    # Component logic here
```

### NPC Decision Cycle
- Runs every 3 seconds (configurable DECISION_INTERVAL)
- Gathers observations using CompositeObservation:
  - NeedsObservation: Current need levels
  - VisionObservation: Visible items and NPCs with interactions
  - StatusObservation: Position, state, current interaction
- Sends formatted observations to backend via client layer
- Executes returned actions through controller state machine

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
- **Private Field Access**: Accessing private fields (prefixed with _) from outside their class is a code smell
  - Create public getter methods instead (e.g., `get_cell_position()` instead of accessing `_gamepiece.cell`)
  - This maintains encapsulation and allows the class to control its interface

### Tool Scripts
- `@tool` scripts run in editor context
- Guard runtime-only code with `if not Engine.is_editor_hint()`
- Be careful with signal connections in tool scripts

### Interaction System Design Philosophy
- **Generic over Specific**: The interaction system is designed to handle ALL interactions through the same state machine states
- **No Special States**: Avoid creating interaction-specific controller states (e.g., ConversingState, EatingState)
- **Interaction Handles Complexity**: Complex behavior belongs in the Interaction class, not the controller state
- **Mock Backend Exception**: Mock backend states can be specialized since they simulate decision-making, not execution
- **Highest Abstraction**: Always work at the highest level of abstraction (e.g., StreamingInteraction for all ongoing interactions)
- **Example**: Conversations use the standard InteractingState, with ConversationInteraction handling all conversation-specific logic

## Common Tasks

### Adding New Item Type
1. Create new ItemConfig resource
2. Add appropriate component configs with PropertySpec definitions
3. Implement InteractionFactory for custom interactions
4. Add to scene or use ItemFactory

### Creating New NPC Behavior
1. Extend base controller states if needed
2. Add new action types to backend
3. Create new observation types if needed
4. Update event formatter for new observations
5. Test with mock backend first

### Adding Multi-Party Interactions
1. Create component extending EntityComponent
2. Implement InteractionFactory that returns is_multi_party() = true
3. Create interaction extending StreamingInteraction
4. Use MultiPartyBid for invitation protocol
5. Handle participant lifecycle with hooks

### Debugging NPCs
- Enable debug logging in NPC scenes
- Use mock backend for predictable behavior
- Check Working Memory panel in UI
- Monitor event flow with EventBus logging

## Current Technical Debt
- Inconsistent debug logging patterns
- Some terminology overloading (Event, Request, Action)
- VisionObservation TODO: NPCs and Items should be treated uniformly
- START_CONVERSATION action needs proper implementation through MultiPartyBid system

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
- **Example**: Use descriptive commit messages that explain what changed and why