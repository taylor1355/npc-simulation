# Events System

## Core Components

### Base Event (event.gd)
- Event type enumeration
- Common event properties
- Type checking utilities

### Event Bus (field_events.gd)
- Global event dispatcher
- Frame-based tracking
- High process priority
- Key signals:
  ```
  event_dispatched: Generic event signal
  gamepiece_clicked: Specific click events
  gamepiece_destroyed: Cleanup events
  npc_created/removed: Lifecycle events
  ```

## Event Collections

### Gamepiece Events (gamepiece_events.gd)
```
Types:
├── CELL_CHANGED
│   ├── gamepiece: Source entity
│   └── old_cell: Previous position
├── PATH_SET
│   ├── gamepiece: Moving entity
│   └── destination: Target cell
├── CLICKED
│   └── gamepiece: Clicked entity
├── DESTROYED
│   └── gamepiece: Removed entity
└── FOCUSED
    └── gamepiece: Selected entity
```

### NPC Events (npc_events.gd)
```
Types:
├── NEED_CHANGED
│   ├── npc: Source entity
│   ├── need_id: Need type
│   └── new_value: Updated value
└── CREATED/REMOVED
    └── npc_id: Unique identifier
```

### NPC Client Events (npc_client_events.gd)
```
Types:
├── INFO_RECEIVED
│   ├── npc_id: Target NPC
│   └── info: State data
└── ACTION_CHOSEN
    ├── npc_id: Actor NPC
    ├── action_name: Choice
    └── parameters: Action data
```

### System Events (system_events.gd)
```
Types:
├── TERRAIN_CHANGED
│   └── affected_cells: Modified positions
└── INPUT_PAUSED
    └── paused: New input state
```

## Usage

### Event Dispatch
```gdscript
# Through FieldEvents singleton
FieldEvents.dispatch(
    GamepieceEvents.create_cell_changed(
        gamepiece,  # Source entity
        old_cell   # Previous position
    )
)
```

### Event Handling
```gdscript
# Generic handler with type check
FieldEvents.event_dispatched.connect(
    func(event: Event):
        if event.is_type(Event.Type.GAMEPIECE_CLICKED):
            handle_click(event as GamepieceEvents.ClickedEvent)
)

# Specific event handler
FieldEvents.gamepiece_clicked.connect(handle_click)
```

### Frame Tracking
```
Cell Change System:
- Tracks position changes per frame
- Clears on frame end
- Query API:
  did_gp_move_to_cell_this_frame()
```

### Common Patterns
```
Entity Lifecycle:
1. Creation events first
2. State change events
3. Destruction events last

State Changes:
1. Update local state
2. Dispatch change event
3. Handle side effects
```
