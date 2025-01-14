# Item System

## Core Components

### Controller (item_controller.gd)
- Manages item behavior and interactions
- Handles component system
- Key properties:
  ```
  components: Array of ItemComponent
  interactions: Dictionary of available interactions
  current_interaction: Active interaction
  interaction_time: Duration of current interaction
  ```

### Components
```
Base (item_component.gd):
└── Shared functionality
    ├── interaction_finished signal
    └── interactions dictionary

Implementations:
├── NeedModifyingComponent
│   ├── Threshold: 1.0
│   ├── need_rates: Changes per second
│   └── Used by other components
├── ConsumableComponent
│   ├── need_deltas: Total changes
│   ├── consumption_time: Duration
│   └── percent_left: Tracks usage
└── SittableComponent
    ├── Energy regen: 10/second
    ├── Movement locking
    └── Exit directions priority
```

### Scene Structure (item.tscn)
```
ItemScene/
├── Decoupler/ (movement smoothing)
├── Animation/
│   ├── AnimationPlayer
│   ├── GFX/
│   │   ├── Sprite
│   │   ├── Shadow
│   │   └── ClickArea (Area2D)
│   └── CollisionArea
└── ItemController/
    └── Components/
```

## Key Features

### Interaction System
```
Flow:
1. request_interaction() called
2. Validate availability
3. Process request type:
   - START: Begin interaction
   - CANCEL: End interaction
4. Handle acceptance/rejection
5. Track interaction time
6. Emit completion
```

### Physics Setup
```
Collision Shapes:
- ClickArea: Interaction zone
  CircleShape2D: radius 6.5-7.5 (Apple)
  RectangleShape2D: 13x19 (Chair)
- CollisionArea: Movement blocking
  Matches visual bounds
  Uses appropriate masks
```

### Component Integration
```
Usage:
1. Add component in _ready()
2. Configure properties
3. Connect to signals
4. Handle interaction_finished

Example:
var component = ConsumableComponent.new()
component.need_deltas = {"hunger": 50}
component.consumption_time = 5.0
add_child(component)
```

## Usage

### Required Setup
```
1. Inherit gamepiece.tscn
2. Add animation scene:
   - AnimationPlayer (idle)
   - Sprite (configured)
   - Collision shapes
3. Add ItemController
4. Configure components
```

### Common Patterns
```
Consumable Items:
- Set need_deltas
- Configure consumption_time
- Handle destruction

Static Items:
- Set blocking state
- Configure interactions
- Handle state changes
```
