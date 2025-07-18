# UI Behavior System

The behavior system provides reactive visual feedback when players interact with the game world. Rather than hardcoding responses to hover, click, and other events, behaviors are configured centrally and applied consistently across all UI elements.

## Core Concepts

**Behaviors** are small, focused classes that respond to specific UI events. A behavior might highlight an entity on hover, open a panel on click, or draw lines between conversation participants.

**Triggers** define the conditions under which a behavior activates. A trigger might specify "when hovering over an NPC that's in a conversation" or "when clicking any item with a consumable component."

**The Registry** matches events to triggers and executes the appropriate behaviors. This central coordination ensures behaviors don't conflict and execute in the right order.

## Creating Behaviors

All behaviors extend `BaseUIBehavior`:

```gdscript
extends BaseUIBehavior

func on_hover_start(gamepiece: Gamepiece) -> void:
    # Apply visual effect when hover starts
    HighlightManager.highlight(
        gamepiece.entity_id,
        "my_behavior",  # Unique source ID
        Color(1.2, 1.2, 1.2),  # Highlight color
        HighlightManager.Priority.HOVER
    )

func on_hover_end(gamepiece: Gamepiece) -> void:
    # Remove effect when hover ends
    HighlightManager.unhighlight(gamepiece.entity_id, "my_behavior")
```

Each behavior implements only the event handlers it needs. The base class provides empty implementations for all events.

## Behavior Triggers

Triggers use a fluent interface to define activation conditions:

```gdscript
# Simple trigger - hover over any NPC
UIBehaviorTrigger.for_event("hover")
    .with_entity("npc")

# Complex trigger - click on NPC in conversation
UIBehaviorTrigger.for_event("click")
    .with_entity("npc")
    .with_state("interacting")
    .with_interaction("conversation")

# Component-based trigger - hover over consumable items
UIBehaviorTrigger.for_event("hover")
    .with_entity("item")
    .with_components(["ConsumableComponent"])
```

The more specific your trigger, the better performance and easier debugging.

## Built-in Behaviors

**HighlightOnHoverBehavior** - Highlights entities on hover with two modes:
- `SELF` - Highlights the hovered entity
- `INTERACTION` - Highlights all participants in the entity's current interaction

**SelectBehavior** - Focuses entities on click, updating the bottom panel display.

**MultiPartyInteractionBehavior** - Manages interaction lines by coordinating with InteractionLineManager when interactions start/end.

**OpenPanelBehavior** - Opens floating windows for active interactions.

**PulseBehavior** - Creates animated pulsing effects on sprites.

**ShowTooltipBehavior** - Displays configurable tooltips with text substitution.

## Configuration

Behaviors are registered in `UIBehaviorConfig`:

```gdscript
static func get_all_behaviors() -> Array[TriggeredBehavior]:
    return [
        # Highlight any hovered entity
        TriggeredBehavior.new(
            UIBehaviorTrigger.for_event("hover"),
            TintHoverBehavior,
            { "highlight_color": Color(1.1, 1.1, 1.1) }
        ),
        
        # Select clicked entities
        TriggeredBehavior.new(
            UIBehaviorTrigger.for_event("click"),
            SelectBehavior,
            {}
        ),
        
        # More behaviors...
    ]
```

The configuration maps triggers to behavior classes with optional parameters.

## Visual Feedback Systems

**HighlightManager** (`src/ui/behaviors/visual_effects/highlight_manager.gd`)
- Manages entity sprite highlighting with priority-based color selection
- Multiple sources can highlight the same entity (hover, selection, interaction)
- Higher priority highlights override lower ones

**InteractionLineManager** (`src/field/interaction_line_manager.gd`)  
- Draws lines between interaction participants
- Supports different line styles per interaction type
- Coordinates with behaviors for hover highlighting

## Event Flow

1. **UI Event occurs** (hover, click, etc.)
2. **UIRegistry receives event** through EventBus
3. **Registry finds matching behaviors** based on triggers
4. **Behaviors execute in priority order**
5. **Visual effects apply** through color manager or other systems
6. **State updates** in the registry's tracker

## Creating Custom Behaviors

To add a new behavior:

1. **Identify the need** - What visual feedback is missing?
2. **Create behavior class** extending BaseUIBehavior
3. **Implement event handlers** for relevant events
4. **Define trigger conditions** for when it activates
5. **Register in config** with appropriate parameters
6. **Test thoroughly** with edge cases

Example: Pulse effect on low health NPCs:

```gdscript
extends BaseUIBehavior

var pulse_speed: float = 2.0

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    # Pulse logic for tracked NPCs
    for entity_id in tracked_entities:
        var intensity = sin(Time.get_ticks_msec() * 0.001 * pulse_speed)
        var color = Color(1.0 + intensity * 0.3, 1.0, 1.0)
        get_color_manager().add_modification(entity_id, "pulse", color)

func should_pulse(gamepiece: Gamepiece) -> bool:
    var needs = gamepiece.get_component(NeedsManager)
    return needs and needs.get_lowest_need_value() < 30
```

## Best Practices

**Keep behaviors focused** - Each behavior should do one thing well. Complex effects should be split into multiple behaviors.

**Use appropriate events** - Hover for temporary effects, click for persistent changes, focus for panel updates.

**Clean up properly** - Always remove effects in the corresponding end event (hover_ended, etc.)

**Test combinations** - Ensure behaviors work together (hover + selection + interaction highlighting).

**Consider performance** - Behaviors execute frequently, so keep them lightweight.

## Debugging

To debug behavior issues:

1. **Enable behavior logging** in UIRegistry
2. **Check trigger conditions** - Are they too specific or too general?
3. **Verify event flow** - Are the expected events being dispatched?
4. **Inspect state tracker** - Is the UI state what you expect?
5. **Test in isolation** - Disable other behaviors to identify conflicts

The behavior system makes it easy to add rich visual feedback throughout the game while maintaining consistency and performance.