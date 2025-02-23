# Item System

## Core Components

### Controller (item_controller.gd)
```
Key Features:
├── Component Management
│   ├── add_component(config: ItemComponentConfig)
│   ├── add_component_node(component: GamepieceComponent)
│   └── Automatic interaction registration
├── Interaction System
│   ├── interactions: Dictionary of available actions
│   ├── current_interaction: Active interaction
│   ├── interacting_npc: Current NPC reference
│   └── interaction_time: Duration tracking
└── Event Handling
    └── interaction_finished signal
```

### Component System
```
Base Component:
├── Properties
│   ├── interactions: Dictionary
│   └── interaction_finished signal
└── Integration
    ├── Automatic controller discovery
    └── Event forwarding

ConsumableComponent Example:
├── Configuration
│   ├── need_deltas: Dictionary (need changes)
│   └── consumption_time: float (duration)
├── State
│   ├── percent_left: float (0-100)
│   └── current_npc: NpcController
├── Features
│   ├── Creates NeedModifyingComponent
│   ├── Configures need rates
│   └── Auto-cleanup at 0% percent_left
└── Interaction Flow
    ├── Start: Validates and begins consumption
    ├── Process: Updates percent_left
    ├── Cancel: Handles early termination
    └── Finish: Cleanup and destruction
```

### Component Configuration
```
ItemComponentConfig:
├── component_script: Script reference
├── properties: Dictionary
└── _validate(): Verification method

Validation:
├── Script inheritance check
├── Property type verification
└── Required field validation
```

## Integration

### Component Setup
```gdscript
# Create and configure component
var component = ConsumableComponent.new()
component.need_deltas = {
    "hunger": hunger_need_delta,  # Configure rates at which
    "energy": energy_need_delta   # consumption affects needs
}
component.consumption_time = duration  # Set consumption duration

# Add to controller
item_controller.add_component_node(component)
```

### Interaction Flow
```
Request Phase:
1. NPC sends InteractionRequest
2. Controller validates:
   - No current interaction
   - Interaction exists
   - Valid request type
3. Component handles request:
   - Validates preconditions
   - Sets up state
   - Configures related components

Execution:
1. Controller tracks time
2. Component updates state
3. Monitors completion
4. Handles cancellation
5. Cleanup on finish
```

### Event System
```
Interaction Events:
├── Start Request
│   ├── Validation
│   └── State setup
├── Cancel Request
│   ├── State verification
│   └── Cleanup
└── Finished
    ├── State reset
    ├── Resource cleanup
    └── Event dispatch
```
