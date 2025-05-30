# Gamepiece System

## Core Components

### Base Entity (`src/field/gamepieces/gamepiece.gd`)
The `Gamepiece` class (extends `Node2D`) is the fundamental building block for any entity that exists and moves on the gameboard grid. It manages its logical grid position (`cell`) separately from its visual representation, allowing for smooth movement.

**Key Properties & Features:**
*   **Grid Position:**
    *   `cell: Vector2i`: The gamepiece's current logical cell on the `Gameboard`. Can be set directly via `set_cell(Vector2i)` for instant teleportation.
    *   `direction: Vector2`: A normalized vector indicating the gamepiece's facing direction.
*   **Configuration Exports:**
    *   `@export var display_name: String`: For UI and identification.
    *   `@export var gameboard: Gameboard`: A required reference to the active `Gameboard` resource.
    *   `@export var blocks_movement: bool`: If `true`, this gamepiece (if it has a `CollisionObject2D`) will be considered an obstacle by other gamepieces. Changes emit `blocks_movement_changed`.
    *   `@export var move_speed: float`: Speed in pixels/second for visual movement along a path (default: 64.0).
*   **Decoupled Visual Movement:**
    *   Uses a child `Path2D` (`_path`) and `PathFollow2D` (`_follower`) to animate visual movement.
    *   `travel_to_cell(destination_cell: Vector2i)`: Primary method to initiate movement. Updates `cell` instantly, then the visual representation follows the path.
    *   `camera_anchor: RemoteTransform2D` & `gfx_anchor: RemoteTransform2D`: Nodes within the PathFollow2D structure that external nodes (like cameras or sprites) can use as targets for smooth following.
*   **Interaction:**
    *   `_click_area: Area2D` (expected at path `Animation/GFX/ClickArea`): Used to detect clicks, which then dispatch a `GamepieceEvents.ClickedEvent`.
*   **Utility:**
    *   `get_controller() -> GamepieceController`: Retrieves the first child `GamepieceController` if one exists.
    *   `is_moving() -> bool`: Returns `true` if currently traversing a path.

**Key Signals:**
*   `travel_begun`: Emitted when `travel_to_cell` is called and movement starts.
*   `arriving(remaining_distance: float)`: Emitted just before the `PathFollow2D` reaches the end of its current path segment.
*   `arrived`: Emitted when the `PathFollow2D` has reached its destination.
*   `cell_changed(old_cell: Vector2i)`: Emitted when the `cell` property changes. Also dispatches a global `GamepieceEvents.CellChangedEvent`.
*   `direction_changed(new_direction: Vector2)`: Emitted when the `direction` property changes.
*   `blocks_movement_changed`: Emitted when `blocks_movement` property changes.

### Controller (`src/field/gamepieces/controllers/gamepiece_controller.gd`)
The `GamepieceController` (extends `Node2D`) is responsible for managing the behavior, pathfinding, and environmental awareness of its parent `Gamepiece`. Specialized controllers (like `NpcController` or `ItemController`) inherit from this.

**Key Responsibilities & Features:**
*   **Pathfinding Management:**
    *   Owns and manages a `Pathfinder` instance.
    *   `_rebuild_pathfinder()`: Initializes or rebuilds the `Pathfinder` based on terrain data (queried using `_terrain_searcher`).
    *   `_find_all_blocked_cells()`: Updates the `Pathfinder` by checking for gamepieces that block movement (queried using `_gamepiece_searcher`).
    *   `travel_to_cell(destination: Vector2i, allow_adjacent_cells: bool = false)`: Calculates a path using `Pathfinder` and instructs the parent `Gamepiece` to move.
*   **Environment Querying:**
    *   Uses `CollisionFinder` instances:
        *   `_gamepiece_searcher`: To find other gamepieces (based on `gamepiece_mask`).
        *   `_terrain_searcher`: To find terrain obstacles (based on `terrain_mask`).
    *   `is_cell_blocked(cell: Vector2i) -> bool`: Checks if a cell is occupied by a blocking gamepiece or terrain.
    *   `get_collisions(cell: Vector2i) -> Array[Dictionary]`: Returns all gamepiece collisions at a cell.
*   **Component Management:**
    *   Maintains a list of child `GamepieceComponent`s.
    *   Provides `get_component(type: GDScript)`, `has_component(type: GDScript)`, and `add_component_node(component: GamepieceComponent)`.
*   **State & Event Handling:**
    *   Responds to game events like `FieldEvents.input_paused`, `FieldEvents.terrain_changed`, and `GamepieceEvents.CellChangedEvent` to update its state or pathfinding data.
    *   Connects to parent `_gamepiece` signals (`arriving`, `arrived`) to manage path following.
*   **Configuration Exports:**
    *   `@export_flags_2d_physics var terrain_mask` (default `0x2`).
    *   `@export_flags_2d_physics var gamepiece_mask` (default `0x1`).

### Components (`src/field/gamepieces/controllers/gamepiece_component.gd`)
The `GamepieceComponent` class (extends `Node2D`) is the base class for all components that add specific functionalities or behaviors to a `GamepieceController`.
*   **Controller Link:** In its `_ready()` method, it automatically searches its ancestor nodes to find and store a reference to its `controller: GamepieceController`.
*   **Extensibility:** Designed to be inherited by specialized components (e.g., `ItemComponent`).
*   **Utility:**
    *   `get_component_name() -> String`: Returns a human-readable name derived from its script's filename.
    *   `_setup() -> void`: A virtual method that can be overridden by subclasses for additional initialization after the `controller` reference is set.

### Animation (`gamepiece.tscn`)
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
