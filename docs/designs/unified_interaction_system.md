# Interaction System Guide

## Overview

The interaction system manages all entity interactions in the game, from simple item usage to complex multi-party conversations. It uses contexts to manage interaction state and a global registry to track active interactions and prevent duplicates.

## Architecture

```
InteractionRegistry (singleton)
├── Tracks all active interactions
├── Prevents duplicate interactions
└── Provides context-aware queries

InteractionContext
├── Manages interaction state and lifecycle
├── Handles ENTITY and GROUP interaction types
└── Primary interface for interaction discovery

GamepieceController
├── Base controller with interaction_factories
├── Uses contexts for available interactions
└── No temporary objects created

InteractionFactory
├── Creates interactions on demand
├── Provides metadata without instantiation
└── Validates preconditions
```

## Core Components

### InteractionContext (`interaction_context.gd`)

Manages the state and lifecycle of interactions. Serves as the primary interface for discovering what interactions are available and managing active ones.

**Key Responsibilities:**
- **Interaction Discovery**: Determines available interactions without creating temporary objects
- **Duplicate Prevention**: Checks InteractionRegistry for existing interactions
- **State Management**: Tracks active interaction state
- **Cancellation Handling**: Routes cancellations based on context type (entity vs group)

**Key Properties:**
- `interaction: Interaction` - The active interaction (null if not started)
- `host: GamepieceController` - The entity hosting this context
- `context_type: ContextType` - Either ENTITY or GROUP
- `is_active: bool` - Whether an interaction is currently active

**Context Types:**
- `ENTITY`: Single-party interactions with items or NPCs
- `GROUP`: Multi-party interactions like conversations

### InteractionRegistry (`interaction_registry.gd`)

Global singleton that tracks all active interactions in the game. Accessed directly via autoload.

**Key Responsibilities:**
- **Global Tracking**: Maintains dictionaries of all active interactions
- **Duplicate Prevention**: Provides queries to check existing interactions
- **Lifecycle Management**: Listens to EventBus for interaction events
- **Context Queries**: Returns contexts for specific hosts

**Key Methods:**
- `register_interaction(interaction, context)` - Registers a new active interaction
- `is_participating_in(entity, interaction_type)` - Checks if entity is in an interaction
- `get_contexts_for(host)` - Returns all contexts for a host
- `get_participant_interactions(entity, type)` - Gets interactions for a participant

### GamepieceController Integration

The base controller provides interaction discovery through contexts.

**Key Methods:**
- `get_available_interactions()` - Returns available interactions as metadata dictionary
- `_get_interaction_contexts()` - Gets existing contexts from registry or creates new ones
- `handle_interaction_bid(request)` - Processes incoming interaction requests

### InteractionFactory (`interaction_factory.gd`)

Creates interactions and provides metadata without instantiation.

**Key Methods:**
- `create_interaction(context)` - Creates actual interaction instance
- `get_metadata()` - Returns interaction data without creating instance
- `get_interaction_name()` - Returns the interaction type name
- `can_create_for(entity)` - Validates if interaction can be created

## Usage Patterns

### Discovering Available Interactions

```gdscript
# Vision system or decision-making code
var available = target.get_available_interactions()
# Returns: Dictionary[String, Dictionary]
# Keys are interaction names, values are metadata
```

### Starting an Interaction

```gdscript
# 1. RequestingState creates bid
var bid = InteractionBid.new(name, type, requester, target)

# 2. On acceptance, register with system
InteractionRegistry.register_interaction(interaction, context)

# 3. Transition to InteractingState
var state = ControllerInteractingState.new(controller, interaction, context)
```

### Preventing Duplicates

Duplicate prevention happens at multiple levels:
1. `InteractionContext.can_start_interaction()` checks registry
2. `get_available_interactions()` filters active interactions
3. Registry tracks all participants globally

## State Machine Integration

### RequestingState
- Creates interaction bids and waits for responses
- Registers accepted interactions with InteractionRegistry
- Creates appropriate context based on interaction type

### InteractingState
- Receives context in constructor
- Handles both entity and group interactions
- Uses context for cancellation logic

### Multi-Party Coordination
- MultiPartyBid coordinates multiple participants
- Each participant gets their own context
- Registry tracks all participants

## Common Patterns

### Adding a New Interaction Type

1. Create InteractionFactory subclass:
```gdscript
class MyInteractionFactory extends InteractionFactory:
    func get_interaction_name() -> String:
        return "my_interaction"
    
    func get_metadata() -> Dictionary:
        return {
            "name": get_interaction_name(),
            "description": "Does something special",
            "needs_filled": ["fun"],
            "duration": 5.0
        }
    
    func create_interaction(context: Dictionary) -> Interaction:
        return MyInteraction.new()
```

2. Add factory to component's `_create_interaction_factories()`

### Debugging Interactions

1. Check active interactions:
```gdscript
var interactions = InteractionRegistry.get_participant_interactions(npc)
```

2. Verify context state:
- Check `context.is_active`
- Check `context.interaction` 

3. Use debug logging:
- Enable EventBus interaction event logging
- Check state machine transitions

### Type Safety with Arrays

GDScript's typed array limitations require special handling:
```gdscript
# Converting untyped arrays from dictionaries
var contexts: Array[InteractionContext] = []
if _contexts_by_host.has(host_id):
    contexts.assign(_contexts_by_host[host_id])
```

## Key Concepts

### Context-First Design
Contexts are the primary interface for interaction management. They encapsulate state, provide discovery, and handle lifecycle.

### No Temporary Objects
The system never creates interaction instances just to get metadata. Factories provide this data directly.

### Global Awareness
InteractionRegistry provides system-wide knowledge of active interactions, enabling proper duplicate prevention.

### Backward Compatibility
Existing code continues to work. The familiar `get_available_interactions()` API is preserved.

## Performance Considerations

- Contexts are lightweight and reusable
- No temporary interaction objects created during discovery
- Registry uses efficient dictionary lookups
- Event-based lifecycle reduces polling

## Future Extensions

The architecture supports:
- Late joining for group interactions
- Context pooling for performance
- More sophisticated interaction rules
- Dynamic interaction discovery