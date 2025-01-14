# UI System

## Core Components

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

### Main UI (ui.tscn)
```
Components:
├── Need displays
│   ├── Hunger bar
│   ├── Energy bar
│   ├── Hygiene bar
│   └── Fun bar
└── Memory panel
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

### Global State
```
Tracked State:
├── Focused gamepiece
├── NPC client reference
└── UI update status
```

## Usage

### Need Bar Setup
```gdscript
# Create need display
var need_bar = preload("need_bar.tscn").instantiate()
need_bar.need_id = "energy"
need_bar.label_text = "Energy"

# Add to container
add_child(need_bar)
```

### Memory Display
```gdscript
# Format panel text
memory_text.text = """
State: {state}
Goals: {goals}
Memory: {observations}
"""
```
