# UIRegistry

The UIRegistry singleton coordinates UI behaviors and tracks the current state of UI elements across the game. It serves as the central nervous system for reactive UI feedback.

## Purpose

The registry solves several problems:

**Behavior Coordination** - When multiple behaviors could respond to the same event (like hovering over an NPC), the registry determines which ones should execute and in what order.

**State Management** - The registry tracks what's currently hovered, selected, and focused, preventing conflicts and ensuring consistent behavior.

**Event Routing** - Game events flow through the registry, which routes them to appropriate behaviors based on configured triggers.

## Architecture

The UIRegistry contains three main subsystems:

**BehaviorRegistry** maintains the mapping between triggers and behaviors. When an event occurs, it finds all behaviors with matching trigger conditions.

**UIStateTracker** keeps track of the current UI state - what entity is hovered, what's selected, which windows are open. This state informs behavior decisions.

**Event Processing** connects to the game's event bus and processes relevant UI events, executing matched behaviors in response.

## State Tracking

The state tracker maintains several important states:

```gdscript
# Currently hovered entity (mouse over)
var hover: Gamepiece = null

# Currently focused entity (selected for panel display)  
var focus: Gamepiece = null

# Currently selected entities (for multi-select)
var selection: Array[Gamepiece] = []

# Active interaction highlights
var highlighted_interactions: Dictionary = {}  # entity_id -> interaction_id

# Open floating windows
var tracked_windows: Dictionary = {}  # interaction_id -> window
```

These states update automatically as events flow through the system. When an entity is destroyed, it's automatically removed from all tracked states.

## Behavior Execution

When a UI event occurs, the registry:

1. **Extracts context** from the event (which entity, what type of event)
2. **Finds matching behaviors** based on their trigger conditions  
3. **Sorts behaviors** by priority if multiple match
4. **Executes behaviors** in order, passing the current state
5. **Updates state** based on behavior results

This process happens quickly enough to feel instantaneous to players.

## Event Integration

The registry listens for specific event types:

- **Hover events** - Update hover state and trigger hover behaviors
- **Click events** - Update selection and trigger click behaviors  
- **Focus events** - Update focused entity for panel display
- **Interaction events** - Track interaction lifecycle for UI updates

Each event type has specialized handling to extract the relevant information and update appropriate state.

## Window Management

The registry tracks floating windows to:

- **Prevent duplicates** - Only one window per interaction
- **Enable window lookup** - Find windows by interaction ID
- **Handle cleanup** - Remove tracking when windows close

When checking if a window exists for an interaction, the registry provides authoritative answers.

## Common Patterns

### Checking UI State

```gdscript
# Is something being hovered?
if UIRegistry.get_state_tracker().hover:
    var hovered = UIRegistry.get_state_tracker().hover
    
# What's currently focused?
var focused = UIRegistry.get_state_tracker().focus

# Is a specific window open?
if UIRegistry.has_window_for_interaction(interaction_id):
    var window = UIRegistry.get_window_for_interaction(interaction_id)
```

### Behavior Conditions

The registry executes behaviors based on sophisticated matching:

```gdscript
# Only highlight NPCs in conversations
UIBehaviorTrigger.for_event("hover")
    .with_entity("npc")
    .with_state("interacting")
    .with_interaction("conversation")
```

### State Cleanup

The registry automatically cleans up state when entities are freed:

```gdscript
# In UIStateTracker
func cleanup_freed_references() -> void:
    if hover and not is_instance_valid(hover):
        hover = null
    # Similar for other tracked entities
```

## Performance Considerations

The registry is designed for performance:

- **Event filtering** happens early to avoid unnecessary processing
- **Behavior matching** uses efficient lookups, not iteration
- **State updates** are minimal and targeted
- **Cleanup** runs only when needed, not every frame

## Extending the Registry

To add new UI state tracking:

1. Add state variables to UIStateTracker
2. Create methods to update the state
3. Connect to appropriate events
4. Ensure cleanup when entities are freed

To add new behavior types:

1. Define trigger conditions in UIBehaviorTrigger
2. Create behaviors extending BaseUIBehavior
3. Register in UIBehaviorConfig
4. The registry handles execution automatically

## Integration with Other Systems

The UIRegistry works closely with:

**EventBus** - Source of all UI-relevant events
**UIElementProvider** - Creates UI elements that behaviors might open
**SpriteColorManager** - Manages visual highlighting from behaviors
**FloatingWindowContainer** - Hosts windows tracked by the registry

## Best Practices

**Trust the registry** - Use its state tracking rather than maintaining separate state.

**Clean up properly** - Always remove tracking when elements are destroyed.

**Use specific triggers** - More specific behavior triggers perform better and are easier to debug.

**Avoid state races** - Let the registry manage state updates rather than modifying directly.

The UIRegistry provides a robust foundation for reactive UI behavior, ensuring consistent and performant visual feedback throughout the game.