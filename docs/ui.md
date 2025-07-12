# UI System

## Overview

The UI system provides flexible panels for displaying entity and interaction information. It supports tabbed panels for focused entities, floating windows for interactions, clickable text links, and visual feedback through behaviors and highlighting.

## Required Scene Setup

For the UI system to function properly, the UI scene (`src/ui/ui.tscn`) must include:

```
CanvasLayer
├── TabContainer (entity-focused panels)
├── DebugConsole (developer tools)
└── FloatingWindowContainer (Control node with floating_window_container.gd)
    └── (floating windows added at runtime)
```

**FloatingWindowContainer Requirements:**
- Script: `floating_window_container.gd`
- Group: `"floating_window_container"`
- Mouse Filter: `MOUSE_FILTER_IGNORE`
- Anchors: Full rect to cover screen

## Core Architecture

### Key Singletons

1. **UIElementProvider** (`/src/ui/ui_element_provider.gd`) - Creates and displays all UI elements
2. **UIRegistry** (`/src/common/ui_registry.gd`) - Manages UI behaviors and tracks UI state

### Panel Hierarchy

```
BasePanel (base_panel.gd)
├── EntityPanel (entity_panel.gd) - For entity-focused information
│   ├── NpcInfoPanel - NPC traits and state with clickable links
│   ├── ItemInfoPanel - Item properties
│   ├── NeedsPanel - Need bars display
│   ├── WorkingMemoryPanel - Backend state
│   └── Component panels (Consumable, Sittable, etc.)
└── InteractionPanel (interaction_panel.gd) - For interaction-focused UI
    └── ConversationPanel - Multi-party chat interface
```

### Panel System Features

**BasePanel** provides core lifecycle:
- `activate()` / `deactivate()` - Enable/disable processing
- `_on_activated()` / `_on_deactivated()` - Override for setup/cleanup
- `_update_display()` - Override for content updates

**EntityPanel** features:
- Automatic focus tracking via `FOCUSED_GAMEPIECE_CHANGED` events
- Controller compatibility checking
- Configurable update intervals
- Default/invalid state text display

**InteractionPanel** features:
- Interaction lifecycle tracking
- Historical state support (panels persist after interaction ends)
- `became_historical` signal when interaction completes
- Connection management for interaction-specific signals

## UIElementProvider System

The `UIElementProvider` singleton is responsible for creating and displaying all UI elements:

### Configuration Classes

```gdscript
# Tab panel configuration
var config = UIElementProvider.TabPanelConfig.new(
    "res://src/ui/panels/npc_info_panel.tscn",
    0,  # priority
    "Info"  # display name
)

# Floating window configuration
var window_config = UIElementProvider.FloatingWindowConfig.new(
    "res://src/ui/panels/conversation_panel.tscn",
    "Conversation"
)
window_config.default_size = Vector2(350, 400)
```

### Core Methods

```gdscript
# Display entity panels in tabs
var panels = UIElementProvider.display_entity_panels(controller)

# Display interaction panel as floating window
UIElementProvider.display_interaction_panel(interaction)

# Check if UI exists for an interaction type
if UIElementProvider.has_ui_for_interaction("conversation"):
    # Show link or enable UI
```

### Default Configuration

- **Entity Panels**: NPC info, needs, working memory; Item info with dynamic component panels
- **Interaction Panels**: Conversation (floating window)
- **Component Panels**: Consumable, NeedModifying, Sittable (shown as tabs)

## UI Link System

The UI link system enables clickable text within panels that trigger actions:

### UILink Class

```gdscript
# Create a link to an interaction
var link = UILink.interaction(interaction_id, "Conversation")
text = "Status: " + link.to_bbcode()  # Outputs BBCode formatted link

# Create a link to an entity
var link = UILink.entity(entity_id, npc_name)
text = "Talking with " + link.to_bbcode()
```

### RichTextLabelLink

Panels use `RichTextLabelLink` instead of regular `RichTextLabel` to support clickable links:

```gdscript
@onready var info_text: RichTextLabelLink = $InfoText
info_text.bbcode_enabled = true
info_text.text = npc_controller.get_state_info_text(true)  # true = include links
```

### Natural Link Integration

States format their descriptions with embedded links:
- "💬 Interacting - [Conversation] with Alice" (Conversation is clickable)
- Links open the appropriate UI panel when clicked
- Only shown if the interaction type has a UI panel registered

## UI Behavior System

### Overview

The UI behavior system provides reactive visual feedback based on game state. Behaviors are triggered by specific events and conditions, allowing for context-aware UI responses.

```
UI Behavior Architecture:
├── BaseUIBehavior (base_ui_behavior.gd) - Core behavior interface
├── UIBehaviorTrigger (ui_behavior_trigger.gd) - Matching conditions
├── UIBehaviorConfig (ui_behavior_config.gd) - Behavior registration
└── Concrete Behaviors:
    ├── TintHoverBehavior - Entity hover highlighting
    ├── SelectBehavior - Focus on click
    ├── HighlightTargetBehavior - Interaction highlighting
    └── OpenPanelBehavior - Opens interaction panels
```

### Behavior Registration

Behaviors are registered in `UIBehaviorConfig` with triggers:

```gdscript
TriggeredBehavior.new(
    UIBehaviorTrigger.for_event("hover")
        .with_entity("npc")
        .with_state("interacting")
        .with_interaction("conversation")
        .with_ui_element_type(Globals.UIElementType.NAMEPLATE_EMOJI),
    HighlightTargetBehavior,
    { "highlight_color": Color(1.0, 1.0, 0.5, 0.8) }
)
```

### Color Management

The `SpriteColorManager` coordinates color modifications from multiple sources:
- Uses entity IDs as keys for persistence
- Supports color blending when multiple modifications active
- Automatically restores original colors when modifications removed
- Prevents conflicts between hover, selection, and interaction highlighting

## UI Components

### NPC Nameplate System (`npc_nameplate.gd`)

Floating labels above NPCs showing name and state emoji. Updates automatically on state changes and supports hover/click detection for UI behaviors.

### TabContainer (`tab_container.gd`)

Manages entity-focused panels in tabs. Features include:
- Gets panels from UIElementProvider based on entity type
- Priority-based tab ordering (lower priority = earlier tabs)
- Automatic cleanup when focus changes
- Panel activation management

### Floating Windows (`floating_window.gd`)

Draggable windows for interaction UI:
- Title bar with drag support
- Optional close button
- Handles setup timing (stores config if nodes aren't ready)
- Uses built-in `move_to_front()` for z-ordering

### Debug Console (`debug_console.gd`)

Developer console for runtime debugging:
- Toggle with backtick (`) key
- Command history with up/down arrows
- Built-in commands:
  - `backend mock` / `backend mcp` - Switch AI backends
  - `help` - Show available commands
  - `clear` - Clear console output

## UIRegistry System

The `UIRegistry` singleton manages UI behaviors and tracks UI state:

### Core Features
- **Behavior Management**: Matches and executes behaviors based on triggers
- **State Tracking**: Maintains hover, selection, and highlight states
- **Window Tracking**: Monitors open floating windows

### State Tracking

The `UIStateTracker` maintains UI state:
```gdscript
# Entity states
- hover: Currently hovered entity
- focus: Currently focused entity (for panels)
- selection: Currently selected entities

# Interaction states  
- highlighted_interactions: Interactions with visual emphasis
- tracked_windows: Floating windows by ID with auto-cleanup
```

## Event Flow

### Click Selection
```
1. Mouse clicks on gamepiece
2. GamepieceClickArea detects click
3. GAMEPIECE_CLICKED event dispatched with ui_element_id
4. SelectBehavior creates FOCUSED_GAMEPIECE_CHANGED event
5. TabContainer gets panels from UIElementProvider
6. EntityPanels update their displays
```

### Hover Highlighting
```
1. Mouse enters Area2D (ClickArea, NameplateEmoji, etc.)
2. GAMEPIECE_HOVER_STARTED event dispatched
3. UIRegistry finds matching behaviors
4. TintHoverBehavior applies color via SpriteColorManager
5. Color blends with any existing modifications
6. On hover end, color modification removed
```

### Interaction UI with Links
```
1. NPC state shows "Interacting - [Conversation] with Bob"
2. User clicks [Conversation] link
3. UILink.execute() calls UIElementProvider.display_interaction_panel()
4. UIElementProvider creates panel and floating window
5. Window added to FloatingWindowContainer
6. Panel connects to interaction for updates
7. Window persists after interaction ends (historical state)
```

## Usage Examples

### Creating a Custom Entity Panel
```gdscript
extends EntityPanel

func is_compatible_with(controller: GamepieceController) -> bool:
    return controller.has_component(MyComponent)

func _update_display() -> void:
    if not current_controller:
        return
    var component = current_controller.get_component(MyComponent)
    # Update UI based on component state
```

### Adding a New Interaction Panel
```gdscript
# 1. Create panel extending InteractionPanel
extends InteractionPanel

func _connect_to_interaction() -> void:
    if current_interaction:
        current_interaction.state_changed.connect(_on_state_changed)

func _update_display() -> void:
    # Update UI based on interaction state

# 2. Register in UIElementProvider._ready()
var my_config = FloatingWindowConfig.new(
    "res://path/to/my_panel.tscn",
    "My Interaction"
)
_interaction_panels["my_interaction"] = my_config
```

### Creating a UI Behavior
```gdscript
# 1. Create behavior extending BaseUIBehavior
extends BaseUIBehavior

func on_click(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
    # Handle click behavior

# 2. Register in UIBehaviorConfig
static func get_custom_behaviors() -> Array[TriggeredBehavior]:
    return [
        TriggeredBehavior.new(
            UIBehaviorTrigger.for_event("click")
                .with_entity("item")
                .with_components(["MyComponent"]),
            MyCustomBehavior,
            { "param": "value" }
        )
    ]
```

### Adding Links to State Text
```gdscript
# In a controller state class
func get_state_description(include_links: bool = false) -> String:
    if include_links and target_entity:
        var link = UILink.entity(target_entity.entity_id, target_entity.get_display_name())
        return "Moving to " + link.to_bbcode()
    return "Moving to " + target_entity.get_display_name()
```

## ID System Integration

The UI system uses entity IDs for persistence:
- **Gamepieces** have unique `entity_id` generated on creation
- **UI Elements** have `ui_element_id` for tracking
- **Interactions** have `interaction_id` for panel association
- **Windows** use `IdGenerator.generate_interaction_panel_id()` for consistent IDs

This ensures UI state persists correctly even when object references change.

## Architecture Notes

- States are responsible for formatting their own descriptions with links
- UIElementProvider is the single source of truth for UI configuration
- Floating windows handle their own lifecycle (no manual cleanup needed)
- RichTextLabelLink replaces RichTextLabel for link support