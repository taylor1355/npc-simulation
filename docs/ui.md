# UI System

## Core Components

### Enhanced Panel System (`tab_container.gd`)
The UI system now features a dynamic, priority-based panel management system that automatically creates and organizes panels based on the focused gamepiece.

```
Panel System Architecture:
├── TabContainer (extends Godot TabContainer)
│   ├── Dynamic Panel Creation: Based on compatibility and priority
│   ├── Priority-Based Ordering: Lower priority = earlier tabs
│   ├── Automatic Cleanup: Removes panels when focus changes
│   └── Activation Management: Only active panel processes updates
│
├── Panel Types:
│   ├── Info Panels (priority 0)
│   │   ├── NpcInfoPanel: NPC name, state, traits, emoji indicators  
│   │   └── ItemInfoPanel: Item details and properties
│   ├── NPC Panels (priority 1)
│   │   ├── NeedsPanel: Real-time need bars with progress indicators
│   │   └── WorkingMemoryPanel: Backend memory state display
│   └── Component Panels (priority 1)
│       ├── ConsumablePanel: Consumption progress and effects
│       ├── NeedModifyingPanel: Rate changes and effect descriptions
│       └── SittablePanel: Occupancy state and energy regeneration
│
└── Base Panel (gamepiece_panel.gd):
    ├── Properties
    │   ├── update_interval: Configurable update frequency
    │   └── current_controller: Active gamepiece controller
    ├── Methods
    │   ├── is_compatible_with(): Type compatibility checking
    │   ├── activate()/deactivate(): Lifecycle management
    │   └── _update_display(): Content refresh implementation
    └── Event Integration:
        └── Responds to FOCUSED_GAMEPIECE_CHANGED events automatically
```

### NPC Nameplate System (`npc_nameplate.gd`)

Floating labels above NPCs display their name and current state emoji. The nameplate automatically updates when the NPC's state changes, providing immediate visual feedback about what each NPC is doing.

### Debug Console System (`debug_console.gd`)

A developer console accessible at runtime for debugging and configuration. Toggle it with the backtick (`) key.

**Available Commands:**
- `backend mock` / `backend mcp` - Switch between AI backends
- `help` - Display all available commands
- `clear` - Clear the console output

### Need Display (need_bar.gd, need_bar.tscn)
```
Structure:
├── HBoxContainer
│   ├── RichTextLabel (need name)
│   └── ProgressBar (need value)
Properties:
├── need_id: String (need type)
└── label_text: String (display name)
Updates:
├── On NPC need changes
└── On focused NPC changes
```

### Memory Panel (working_memory_panel.gd)
```
Structure:
├── Panel
└── RichTextLabel (memory text)
States:
├── Empty: "Select an NPC..."
├── Invalid: "Not an NPC..."
└── Active: Shows NPC state
Updates:
├── On NPC selection
└── On info received
```

### NPC Info Panel (npc_info_panel.gd)
```
Structure:
├── Panel
└── RichTextLabel (info text)
Content:
├── Name: NPC display name
├── State: State emoji + name + description
└── Traits: Comma-separated list
Updates:
├── On NPC selection
├── On info received
└── On state changed (via NPC_STATE_CHANGED event)
```

### Main UI Integration (`ui.gd`, `ui.tscn`)
```
Enhanced UI Components:
├── Dynamic Tab Container
│   ├── Auto-generated panels based on focused entity
│   ├── Priority-based tab ordering
│   └── Component-specific information display
├── Debug Console
│   ├── Toggle with backtick (`) key
│   ├── Backend switching commands
│   └── Runtime configuration capabilities
├── NPC Nameplates
│   ├── Floating above each NPC
│   ├── Real-time state emoji indicators
│   └── Display name showing
└── Event-Driven Updates
    ├── Focused gamepiece changes trigger panel updates
    ├── NPC state changes update nameplates
    └── Component status reflected in specialized panels
```

## Event Integration

### Need System
```
Update Flow:
1. NPC need changes
2. NeedChangedEvent dispatched
3. Need bars validate:
   - Matches focused NPC
   - Matches need_id
4. Progress bar updates
```

### Memory System
```
Update Flow:
1. NPC focused
2. FocusedEvent dispatched
3. Panel requests info
4. InfoReceivedEvent arrives
5. Text content updates
```

### State Management
UI panels automatically update based on focused gamepiece. Debug console maintains command history and backend status.

## Usage & Integration

### Debug Console Commands
```gdscript
# Toggle console with backtick key
Input.action_just_pressed("toggle_debug_console")

# Built-in commands:
"backend mock"     # Switch to mock backend
"backend mcp"      # Switch to MCP backend  
"clear"           # Clear console output
"help"            # Show available commands
```

### NPC Nameplate Integration
```gdscript
# Automatic integration - add to NPC scene:
# NpcNameplate node with:
# ├── NameLabel (Label)
# └── EmojiLabel (Label)

# Manual emoji updates (handled automatically):
emoji_label.text = _controller.state_machine.current_state.get_state_emoji()
```

### Panel System Extension
```gdscript
# Create custom panel for new component types
extends GamepiecePanel

func is_compatible_with(controller: GamepieceController) -> bool:
    return controller.has_component(MyCustomComponent)

func _update_display() -> void:
    var component = current_controller.get_component(MyCustomComponent)
    # Update UI based on component state
```

### Enhanced Event Handling
```gdscript
# Panels automatically respond to relevant events:
# - FOCUSED_GAMEPIECE_CHANGED: Triggers panel recreation
# - NPC_STATE_CHANGED: Updates nameplate emojis
# - Component events: Update specialized panels

# Manual event listening:
EventBus.event_dispatched.connect(
    func(event: Event):
        if event.is_type(Event.Type.MY_CUSTOM_EVENT):
            _handle_custom_event(event)
)
```
