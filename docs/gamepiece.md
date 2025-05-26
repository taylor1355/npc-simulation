# Gamepiece System

## Core Components

### Base Entity (gamepiece.gd)
- Grid-based entity with decoupled movement
- Logical position in cell coordinates (Vector2i)
- Visual position follows smoothly via Path2D
- Key signals:
  ```
  travel_begun: Started moving
  arriving(distance): About to reach destination
  arrived: Reached destination
  cell_changed(old_cell): Position updated
  direction_changed(direction): Facing changed
  blocks_movement_changed: Blocking state changed
  ```

### Controller (gamepiece_controller.gd)
- Handles pathfinding and physics
- Physics mask configuration:
  ```
  terrain_mask: 0x2 (static obstacles)
  gamepiece_mask: 0x1 (dynamic entities)
  ```
- Core functions:
  ```
  travel_to_cell(): Move to destination
  is_cell_blocked(): Check occupancy
  get_collisions(): Get entities in cell
  ```
- Component management:
  ```
  get_component(): Get component by type
  has_component(): Check if component exists
  ```

### Components (gamepiece_component.gd)
- Base class for all gamepiece components
- Can be nested at any depth under a controller
- Automatically finds and connects to parent controller
- Extended by specialized components (e.g. ItemComponent)

### Animation (gamepiece.tscn)
```
Animation/
├── AnimationPlayer
└── GFX/
    ├── Sprite (visual representation)
    ├── Shadow (ground shadow)
    └── ClickArea (Area2D, interaction)
```

### Movement System (Path2D)
The node structure for decoupled movement is typically:
```
Gamepiece (Your Scene Root)
└── Decoupler (Node2D, for offset if needed)
    └── Path2D (Defines the movement curve)
        └── PathFollow2D (Follows the Path2D)
            ├── CameraAnchor (Node2D, for camera to target)
            └── GFXAnchor (Node2D, parent for visual elements like Sprite2D)
                └── Sprite2D (Visual representation)
```
This structure allows the `PathFollow2D` to move along the `Path2D`, carrying the `GFXAnchor` (and thus the visuals) smoothly, while the gamepiece's logical cell position can update instantly.

## Key Features

### Decoupled Movement
- Cell position updates instantly
- Visual position follows smoothly
- Camera tracks smoothly
- Move speed: 64.0 pixels/second

### Physics Integration
- CollisionArea for blocking
- ClickArea for interaction
- Configurable collision masks
- Automatic physics updates

### Event System
```
Movement Flow:
1. travel_to_cell() called
2. cell updated instantly
3. travel_begun emitted
4. visuals follow path
5. arriving signal near end
6. arrived on completion

Interaction Flow:
1. ClickArea input detected
2. clicked signal emitted
3. ClickedEvent dispatched
4. Focus system updated
5. Controller processes
```

## Usage

### Required Setup
```
1. Valid gameboard reference
2. Collision shapes if blocking
3. Controller for behavior
4. Animation configuration
```

### Creating Entities
```
1. Inherit gamepiece.tscn
2. Add required nodes:
   - CollisionArea (if blocking)
   - ClickArea (if interactive)
   - Controller (for behavior)
   - Components (for features)
```

### Controller Extension
```gdscript
extends GamepieceController

func _ready():
    super._ready()
    
    # Configure physics
    terrain_mask = 0x2
    gamepiece_mask = 0x1
    
    # Connect signals
    _gamepiece.arriving.connect(_on_arriving)
    _gamepiece.arrived.connect(_on_arrived)
```
