# UIElementProvider

The UIElementProvider singleton serves as the central factory for creating UI elements. It determines which panels should appear for each entity type and creates floating windows for interactions.

## Purpose

Rather than hardcoding which UI panels each entity type should have, the UIElementProvider makes these decisions dynamically based on entity type and components. This allows new entity types and components to automatically get appropriate UI without code changes.

## How It Works

The provider maintains registrations for different types of UI elements:

**Entity panel configs** map entity types to their available panels. When you select an NPC, the provider knows to create info, needs, and working memory panels. When you select an item, it creates panels based on the item's components.

**Interaction panel configs** map interaction types to floating windows. When NPCs start a conversation, the provider creates and configures the conversation window.

**Component panel providers** allow components to supply their own panels. A consumable component can provide a panel showing nutritional information, while a sittable component shows comfort stats.

## Registration

The provider uses configuration objects to define panels:

```gdscript
# Tab panel for entities
var config = UIElementProvider.TabPanelConfig.new(
    "res://src/ui/panels/npc_info_panel.tscn",  # Scene path
    0,  # Priority (lower = earlier in tab order)
    "Info"  # Tab label
)

# Floating window for interactions  
var window_config = UIElementProvider.FloatingWindowConfig.new(
    "res://src/ui/panels/conversation_panel.tscn",
    "Conversation"  # Window title
)
window_config.default_size = Vector2(350, 400)
window_config.show_close_button = true
```

## Dynamic Panel Discovery

When the TabContainer needs panels for an entity, it calls:

```gdscript
var panel_configs = UIElementProvider.get_entity_panel_configs(controller)
```

The provider:
1. Checks the entity type (NPC vs Item)
2. Adds base panels for that type
3. Queries the entity's components for additional panels
4. Returns a combined list sorted by priority

This process happens every time selection changes, ensuring the UI always matches the entity's current state.

## Component Integration

Components can provide their own panels by implementing `get_panel_configs()`:

```gdscript
extends ItemComponent

func get_panel_configs() -> Array[UIElementProvider.TabPanelConfig]:
    return [UIElementProvider.TabPanelConfig.new(
        "res://src/ui/panels/consumable_panel.tscn",
        10,  # Priority  
        "Food Info"
    )]
```

The UIElementProvider automatically discovers these component-provided panels and includes them in the tab list.

## Interaction Windows

For interactions, the provider creates floating windows:

```gdscript
# Check if UI exists for an interaction type
if UIElementProvider.has_ui_for_interaction("conversation"):
    # Create and display the window
    UIElementProvider.display_interaction_panel(interaction)
```

The provider:
1. Looks up the window configuration
2. Creates the panel instance
3. Creates a FloatingWindow container
4. Adds it to the FloatingWindowContainer
5. Returns the configured window

## Default Configuration

The provider comes with sensible defaults:

**NPC panels:**
- Info (priority 0) - Name, state, traits
- Needs (priority 10) - Hunger, energy, etc.
- Working Memory (priority 20) - AI state

**Item panels:**
- Info (priority 0) - Name and type
- Component panels (priority 10+) - Based on item components

**Interaction panels:**
- Conversation - Floating chat window

## Extending the System

To add new panel types:

1. **Create the panel scene** extending the appropriate base class
2. **Register with the provider** in its `_ready()` method
3. **Set appropriate priority** to control tab ordering

For component-specific panels:
1. **Implement `get_panel_configs()`** in your component
2. **Return config objects** for your panels
3. **The provider handles the rest** automatically

## Best Practices

**Use priorities wisely** - Lower numbers appear first. Leave gaps (0, 10, 20) for future panels.

**Name panels clearly** - Tab labels should be short but descriptive.

**Configure windows appropriately** - Set sensible default sizes and positions for floating windows.

**Cache configs if expensive** - The provider calls `get_panel_configs()` on every selection change.

## Common Patterns

### Conditional Panels

Show panels only when certain conditions are met:

```gdscript
func get_panel_configs() -> Array[UIElementProvider.TabPanelConfig]:
    var configs = []
    
    if has_nutrition_data:
        configs.append(nutrition_panel_config)
    
    if is_cookable:
        configs.append(cooking_panel_config)
        
    return configs
```

### Shared Panel Scenes

Multiple components can use the same panel scene with different configurations:

```gdscript
# In ConsumableComponent
return [UIElementProvider.TabPanelConfig.new(
    "res://src/ui/panels/stats_panel.tscn", 10, "Nutrition"
)]

# In WeaponComponent  
return [UIElementProvider.TabPanelConfig.new(
    "res://src/ui/panels/stats_panel.tscn", 10, "Damage"
)]
```

The panel determines what to display based on the component type.

## Performance

The provider is designed for performance:

- **Configs are lightweight** - Just data objects, no scene loading
- **Panels are created on demand** - Only when actually displayed
- **Discovery is fast** - Simple array concatenation
- **No polling** - Only runs when selection changes

The system scales well even with many component types and panel configurations.