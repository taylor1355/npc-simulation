# NPC Simulation Development Guide

## Project Overview

A 2D NPC simulation game built with Godot 4.3+ where NPCs autonomously interact with items and each other in a grid-based world. NPCs make decisions based on their internal needs, choosing between available interactions to satisfy those needs. The project uses a component-based architecture with event-driven communication.

## Running & Testing

- Open the project in Godot 4.3 or later
- Run main.tscn with F5
- **Controls**: Right-click drag to pan camera, mouse wheel to zoom, 'A' to anchor camera to selected NPC
- **Mock Backend**: Available for testing without MCP server (enable in NPC scenes)
- **Debug Console**: Press ` (backtick) to toggle console for runtime backend switching

## Project Structure

```
src/
├── common/          # Shared systems and utilities
│   ├── events/      # Event system with typed event classes
│   ├── globals.gd   # Global constants and utilities
│   └── interaction_registry.gd  # Tracks all active interactions
├── field/           # Core game systems
│   ├── gamepieces/  # Base entity system for movement and animation
│   │   └── components/  # EntityComponent base for items and NPCs
│   ├── gameboard/   # Grid management and pathfinding
│   ├── npcs/        # NPC behavior and decision-making
│   │   ├── components/   # NPC-specific components like ConversableComponent
│   │   ├── controller/   # State machine managing NPC behavior
│   │   ├── client/       # Backend communication layer
│   │   └── observations/ # Structured data for decision-making
│   ├── items/       # Item system with configurable components
│   └── interactions/# Bid-based interaction system
└── ui/              # Interface panels and displays
```

## Core Architecture

### Three-Tier NPC System

The NPC system separates simulation from decision-making through three layers:

1. **Controller** (GDScript): Manages the NPC's physical presence in the world, executes actions through a state machine, and gathers observations about the environment.

2. **Client** (GDScript + C#): Handles communication with the decision-making backend, caching responses and managing the protocol between simulation and AI.

3. **Backend** (MCP Server or Mock): Makes decisions based on observations from the simulation. The mock backend provides predictable behavior for testing, while the MCP backend enables sophisticated AI decision-making.

### Component-Based System

Components define capabilities and behaviors that can be mixed and matched:

- **EntityComponent**: The base class for all components provides property configuration through PropertySpec, automatic type conversion and validation, and interaction factory support.

- **Item Components**: Components like Consumable, Sittable, and NeedModifying define how items can be used and what effects they have on NPCs.

- **NPC Components**: Components like ConversableComponent add capabilities to NPCs, enabling multi-party conversations and other social interactions.

Components are configured through Godot resources, making the system data-driven and easy to extend without code changes.

### Event-Driven Communication

All game systems communicate through a central EventBus that dispatches strongly-typed events. Events are organized by category (gamepiece events, NPC events, interaction events) and include frame-based tracking to ensure consistent timing across systems.

## Key Systems

### Grid & Movement

The game world uses a grid-based system where entities occupy discrete cells:

- **Gameboard**: Manages the grid structure, converts between cell coordinates and pixel positions, and defines world boundaries.

- **Pathfinder**: Implements A* pathfinding with dynamic obstacle support, allowing NPCs to navigate around static terrain and other entities.

- **Gamepiece**: The base entity class maintains both logical grid position and visual pixel position, enabling smooth movement animations while keeping game logic discrete.

### Interaction System

Interactions follow a bid-based pattern where NPCs request interactions and targets accept or reject them:

- **InteractionBid**: Represents a request to start or cancel an interaction. The bidder proposes an interaction, and the target evaluates whether to accept.

- **InteractionFactory**: Each component provides factories that create configured interactions. Factories also provide metadata without creating temporary objects.

- **Interaction**: The base class orchestrates an interaction's lifecycle, managing participants and dispatching events.

- **InteractionContext**: Manages interaction state and discovery. A single context type handles both single-party interactions (with items or NPCs) and multi-party interactions (like conversations).

- **InteractionRegistry**: A global singleton tracks all active interactions, preventing duplicates and enabling queries about who is interacting with whom.

### Need System

NPCs have four core needs that drive their behavior:

- **HUNGER, HYGIENE, FUN, ENERGY**: Each ranges from 0 to 100, decaying over time at configurable rates.

- **Need Satisfaction**: Items can fill or drain needs through the NeedModifyingComponent. NPCs choose interactions based on which needs are lowest and which items can satisfy them.

- **Decision Making**: The NPC's current need levels are included in observations sent to the backend, influencing which actions the AI chooses.

### Vision System

NPCs perceive their environment through a configurable vision range:

- **Vision Manager**: Detects items and other NPCs within range using Godot's Area2D system.

- **Distance Sorting**: Visible entities are sorted by distance, allowing NPCs to prioritize nearby interactions.

- **Observation Data**: Vision information is packaged into observations that include available interactions for each visible entity.

### Conversation System

Multi-party conversations demonstrate the flexibility of the interaction system:

- **ConversableComponent**: Enables NPCs to initiate and participate in conversations with up to 10 participants.

- **MultiPartyBid**: Manages the invitation protocol where all invited NPCs must accept for the conversation to begin.

- **ConversationInteraction**: Extends StreamingInteraction to maintain message history and send updates to all participants.

- **Movement Locking**: Participants cannot move during conversations, ensuring they stay together visually.

- **Standard States**: Conversations use the same InteractingState as other interactions, demonstrating system consistency.

### Observation System

The observation system provides structured data to the decision-making backend:

- **CompositeObservation**: Bundles multiple observation types into a single package for each decision cycle.

- **Core Observations**:
  - NeedsObservation reports current need levels as percentages
  - VisionObservation lists visible entities with their available interactions
  - StatusObservation provides NPC position, state, and current activity
  - ConversationObservation includes message history for ongoing conversations

- **Event Observations**: The system also observes interaction requests, rejections, and other events that might influence decisions.

## Physics Layers

The project uses specific physics layers for different detection needs:

- `0x1` (1): Gamepiece - Entity detection and movement blocking
- `0x2` (2): Terrain - Static obstacles for pathfinding
- `0x4` (4): Click - Mouse interaction detection

## Code Style Guidelines

### Naming Conventions
- **Classes**: PascalCase (e.g., GamepieceController)
- **Variables/Functions**: snake_case (e.g., current_interaction)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., MAX_NEED_VALUE)
- **Private members**: underscore prefix (e.g., _vision_manager)
- **Signals**: snake_case (e.g., need_changed)
- **Event Types**: PascalCase with "Event" suffix (e.g., GamepieceMovedEvent)

### Code Organization
- **Comments**: Focus on explaining why something is done, not just what it does. Avoid overly specific context that won't make sense later.
- **Control Flow**: Use early returns and guard clauses to reduce nesting. Flat code is more readable than deeply nested code.
- **Encapsulation**: Access private fields through public methods rather than directly. This maintains clean interfaces between classes.

## Development Patterns

### Event Handling

Events can be handled directly for specific types or generically with type checking:

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

### Creating Items

Items are created through configuration rather than code:

1. Create an ItemConfig resource in the editor
2. Configure the sprite, collision shape, and interaction shape
3. Add ItemComponentConfig entries for each desired behavior
4. Use ItemFactory.create_item() or place the configured item directly in the scene

### Creating Components

Components follow a standard pattern for property definition and interaction:

```gdscript
extends ItemComponent

func _init():
    # Define configurable properties
    PROPERTY_SPECS["duration"] = PropertySpec.new(
        "duration",
        TypeConverters.PropertyType.FLOAT,
        5.0,
        "How long the interaction lasts"
    )

var duration: float = 5.0

func _component_ready():
    # Component is configured and ready to use
    pass

func _create_interaction_factories() -> Array[InteractionFactory]:
    # Return factories that create interactions for this component
    return [MyInteractionFactory.new(self)]
```

### NPC Decision Cycle

NPCs make decisions on a regular cycle rather than every frame:

1. Every 3 seconds (configurable), the NPC gathers observations about its current state
2. These observations include needs, visible entities, and current activities
3. The observations are sent to the backend as a batch
4. The backend returns an action to execute
5. The controller's state machine executes the action

## Important Patterns & Gotchas

### Resource Management
- Always implement cleanup in _exit_tree() to prevent memory leaks
- Disconnect signals when nodes are freed
- Clear references to other nodes

### Timing & Updates
- Physics updates have a one-frame delay from logical updates
- Use frame-based tracking for consistent event timing
- The EventBus processes at very high priority (-1000) to ensure events are handled first

### Component Access
- Use get_controller() to access the component's controller
- Controllers manage state and behavior execution
- Components define properties and capabilities
- Create public getter methods rather than accessing private fields directly

### Tool Scripts
- Scripts marked with @tool run in the editor context
- Guard runtime-only code with `if not Engine.is_editor_hint()`
- Be careful with signal connections in tool scripts

### Interaction System Philosophy
The interaction system is designed to be generic and reusable:

- All interactions use the same state machine states (no ConversingState, EatingState, etc.)
- Complex behavior belongs in the Interaction class, not in specialized controller states
- The mock backend can have specialized states since it simulates decision-making
- Work at the highest level of abstraction possible

## Common Tasks

### Adding a New Item Type
1. Create a new ItemConfig resource
2. Add appropriate component configs with property definitions
3. Implement any custom InteractionFactory classes needed
4. Add the configured item to the scene

### Creating New NPC Behavior
1. Extend existing controller states only if absolutely necessary
2. Add new action types to the backend's action vocabulary
3. Create new observation types if new information is needed
4. Update the event formatter to include new observations
5. Test with the mock backend first

### Adding Multi-Party Interactions
1. Create a component that extends EntityComponent
2. Implement an InteractionFactory where is_multi_party() returns true
3. Create an interaction extending StreamingInteraction
4. Use MultiPartyBid for the invitation protocol
5. Handle participant lifecycle with the provided hooks

### Debugging NPCs
- Enable debug logging in NPC scenes
- Use the mock backend for predictable, repeatable behavior
- Check the Working Memory panel in the UI to see NPC state
- Monitor event flow with EventBus logging
- Use the debug console to switch backends at runtime

## Documentation Index

The project documentation is organized to help you find information quickly:

### Core System Documentation
- **`docs/interaction.md`**: Complete guide to the interaction system, including bids, factories, and contexts
- **`docs/conversation.md`**: Details on multi-party conversations and the invitation protocol
- **`docs/npc.md`**: NPC architecture, state machine, observation system, and decision cycle
- **`docs/items.md`**: Item system, components, and configuration through resources
- **`docs/gamepiece.md`**: Base entity system for movement and positioning
- **`docs/gameboard.md`**: Grid system, pathfinding, and coordinate conversions
- **`docs/collision.md`**: Physics layers and collision detection patterns
- **`docs/events.md`**: Event system architecture and usage patterns
- **`docs/ui.md`**: UI panels and information display systems

### Getting Started
- **`docs/getting-started.md`**: Quick introduction to running and understanding the project
- **`docs/designs/`**: Design documents and architectural decisions
- **`docs/meta/style-guide.md`**: Documentation and code style guidelines
- **`docs/meta/technical_debt.md`**: Known issues and improvement opportunities
- **`docs/meta/known_bugs.md`**: Current bugs and their workarounds

## Testing Strategies

- Use the mock backend for deterministic testing of game mechanics
- Test components individually with focused test scenes
- Verify event flow with debug logging enabled
- Check frame-based timing with position tracking events
- Use the debug console to test backend switching

## Performance Considerations

The system is designed for efficiency:

- NPCs make decisions every few seconds, not every frame
- Vision checks use Area2D for efficient collision detection
- Pathfinding caches results when possible
- The event system uses Godot's signal system for native performance
- Interaction discovery avoids creating temporary objects

## Pre-Commit Workflow

Before committing changes:

1. Run `git diff` to review all changes
2. Verify the changes match what was intended
3. Check for any unintended modifications
4. Write a clear commit message that explains what changed and why

## Commit Message Style

Commit messages should be clear and informative:

- **First line**: Describe what changed in the fewest words while being comprehensive
- **Empty line**: Always leave a blank line after the header
- **Details**: Add bullet points explaining:
  - Which files or systems were affected
  - The technical reason for the change
  - Any breaking changes or compatibility notes
  - Root causes of bug fixes