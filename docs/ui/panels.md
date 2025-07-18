# Panel System

The panel system provides a framework for creating UI panels that display game information. Every panel in the UI - from NPC needs bars to conversation windows - builds on this foundation.

## Core Concepts

Panels follow a consistent lifecycle pattern. They activate when shown, update periodically while visible, and deactivate when hidden. This ensures panels only consume resources when actually being used.

The system distinguishes between two types of panels based on what they display:

**Entity panels** show information about whatever entity is currently selected. Click on an NPC and these panels update to show that NPC's data. Click on an item and they switch to show item information. The panels themselves decide if they're compatible with the selected entity.

**Interaction panels** display ongoing interactions like conversations. They're tied to a specific interaction rather than following the selected entity. This lets you monitor a conversation while clicking around to inspect other NPCs.

## BasePanel

All panels inherit from `BasePanel`, which provides the core lifecycle management:

```gdscript
extends BasePanel

@export var update_interval: float = 0.1  # How often to refresh

func _on_activated() -> void:
    # Called when panel becomes visible
    # Connect to signals, initialize display
    
func _on_deactivated() -> void:
    # Called when panel is hidden
    # Disconnect signals, clean up
    
func _update_display() -> void:
    # Called every update_interval while active
    # Refresh the panel's content
```

The base class handles the timing and activation logic. Your panel just needs to implement what happens during each lifecycle phase.

## EntityPanel

Entity panels extend the base with logic for tracking the focused gamepiece:

```gdscript
extends EntityPanel

func is_compatible_with(controller: GamepieceController) -> bool:
    # Return true if this panel can display this entity type
    return controller is NpcController
    
func _update_display() -> void:
    if not current_controller:
        info_label.text = "Select an NPC"
        return
        
    var npc = current_controller as NpcController
    info_label.text = npc.get_display_name()
```

The panel system automatically calls `is_compatible_with()` when the selection changes. If compatible, the panel receives the new controller and updates its display.

## InteractionPanel  

Interaction panels connect to specific interactions rather than the global selection:

```gdscript
extends InteractionPanel

func _connect_to_interaction() -> void:
    if current_interaction:
        current_interaction.message_sent.connect(_on_message)
        current_interaction.interaction_ended.connect(_on_ended)
        
func _on_ended() -> void:
    # Panel becomes "historical" - dims slightly but stays usable
    modulate = Color(0.8, 0.8, 0.8)
```

When an interaction ends, the panel enters a "historical" state. It remains visible and functional but visually indicates the interaction is complete.

## Creating Panels

To create a new panel, decide what it should display:

**For entity information:**
1. Extend `EntityPanel`
2. Override `is_compatible_with()` to define which entities it supports
3. Implement `_update_display()` to show the entity's data
4. Register it with UIElementProvider

**For interactions:**
1. Extend `InteractionPanel`
2. Override `_connect_to_interaction()` to link to interaction signals
3. Implement `_update_display()` to show interaction state
4. Register as a floating window or tab panel

## Common Patterns

### Needs Display

The needs panel shows progress bars for each NPC need:

```gdscript
extends EntityPanel

@onready var hunger_bar: ProgressBar = $HungerBar

func is_compatible_with(controller: GamepieceController) -> bool:
    return controller.has_component(NeedsManager)
    
func _update_display() -> void:
    var needs = current_controller.get_component(NeedsManager)
    hunger_bar.value = needs.get_need_percentage("hunger")
```

### Component Information

Item panels often display component properties:

```gdscript
extends EntityPanel

func is_compatible_with(controller: GamepieceController) -> bool:
    return controller.has_component(ConsumableComponent)
    
func _update_display() -> void:
    var consumable = current_controller.get_component(ConsumableComponent)
    info_text.text = "Restores %d hunger" % consumable.hunger_value
```

### Conversation History

The conversation panel maintains a scrolling message list:

```gdscript
extends InteractionPanel

@onready var messages: ItemList = $Messages

func _connect_to_interaction() -> void:
    current_interaction.message_sent.connect(_add_message)
    
func _add_message(sender: String, text: String) -> void:
    messages.add_item("%s: %s" % [sender, text])
    messages.ensure_current_is_visible()
```

## Performance Considerations

Panels only process updates while active, but you should still be mindful of performance:

- Set `update_interval` as high as reasonable (0.1-0.5 seconds for most panels)
- Cache expensive calculations between updates
- Use signals for event-driven updates rather than constant polling
- Avoid creating new nodes during `_update_display()`

## Panel Registration

Panels must be registered with UIElementProvider to appear in the UI. The UIElementProvider singleton manages dynamic panel creation based on entity type and components.

The registration determines:
- Whether the panel appears as a tab or floating window
- The panel's priority (for tab ordering)
- Which entity types or interactions trigger the panel

## Best Practices

### Safe Entity References

When panels need to reference other entities (not just the focused one), use EntityRegistry for safe lookups:

```gdscript
func _display_interaction_target(target_id: String) -> void:
    var target = EntityRegistry.get_entity(target_id)
    if target:  # Always check - entity might have been freed
        target_label.text = target.get_display_name()
    else:
        target_label.text = "(no longer exists)"
```

### Interactive Entity Names

Make entity names clickable using UILinks:

```gdscript
func _display_conversation_participant(participant_id: String, name: String) -> void:
    var link = UILink.entity(participant_id, name)
    rich_text_label.append_text("Talking with ")
    rich_text_label.append_text(link.to_bbcode())
```

This allows players to:
- Click names to focus the camera on that entity
- Hover names to highlight the entity in the game world
- Navigate complex interactions more easily

## Tips for Panel Development

**Start simple** - Get basic information displaying before adding complex features.

**Handle edge cases** - Always check for null controllers and missing components.

**Provide feedback** - Show meaningful messages when no entity is selected or data is unavailable.

**Test thoroughly** - Verify panels update correctly when switching between different entity types.

**Consider mobile** - Ensure panels remain usable on smaller screens if your game targets mobile devices.