# Item System

## Core Components

### Configuration (item_config.gd)
Resource-based configuration that defines:
- Item name and display properties
- Sprite settings (texture, frames, animation)
- Collision shape configuration
- List of component configurations
- Saved as .tres resources in configs/ directory

### Controller (item_controller.gd)
Manages item behavior and state:
- Tracks available interactions
- Handles interaction requests and timing
- Manages component lifecycle
- Emits interaction events
- Maintains component registry

### Components
```
Base (item_component.gd):
└── Shared functionality
    ├── interaction_finished signal
    ├── interactions dictionary
    └── Automatic controller discovery

Implementations:
├── NeedModifyingComponent
│   ├── Threshold: 1.0
│   ├── need_rates: Changes per second
│   ├── Handles continuous effects
│   └── Updates on physics tick
├── ConsumableComponent
│   ├── need_deltas: Total changes
│   ├── consumption_time: Duration
│   ├── Handles one-time use
│   └── Auto-cleanup after use
└── SittableComponent
    ├── Energy regeneration
    ├── Movement locking
    ├── Exit direction handling
    └── Uses NeedModifyingComponent
```

### Scene Structure (base_item.tscn)
```
BaseItem/
├── Decoupler/ (movement smoothing)
├── Animation/
│   ├── AnimationPlayer
│   ├── GFX/
│   │   ├── Sprite (configurable)
│   │   ├── Shadow (automatic)
│   │   └── ClickArea (interaction zone)
│   └── CollisionArea (movement blocking)
└── ItemController/
    └── Components/ (runtime populated)
```

## Usage

### Editor Integration
The BaseItem node provides direct editor support:
- Drag and drop placement in scenes
- Live preview of sprite and collision
- Auto-sized click areas for interaction
- Visual configuration through inspector
- Components initialize automatically at runtime

### Runtime Creation
ItemFactory provides centralized item creation:
- Validates configurations
- Handles instantiation and setup
- Sets required references (gameboard, etc)
- Positions items correctly
- Helper methods for common items
- Consistent with editor-placed items

### Creating New Items
1. Configuration:
   - Create new ItemConfig resource
   - Configure visual properties
   - Set up collision shape
   - Add required component configs
   - Save as .tres resource

2. Component Setup:
   - Choose appropriate components
   - Configure component properties
   - Set up interactions if needed
   - Handle completion events

### Physics Setup
Collision is handled through two areas:
- ClickArea for interactions
  - Automatically sized larger than collision
  - CircleShape2D: radius + 1.0
  - RectangleShape2D: size + Vector2(2, 2)
- CollisionArea for movement
  - Matches visual bounds
  - Uses appropriate collision masks
  - Handles pathfinding obstacles
