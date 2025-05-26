# Gameboard System

## Core Components

### Pathfinder (pathfinder.gd)
- AStar2D wrapper for Vector2i coordinates
- Validates paths against boundaries
- Manages blocked/unblocked cells
- Key operations:
  ```
  get_path_cells(): Direct path between cells
  get_path_cells_to_adjacent_cell(): Path to cell next to target
  block_cell(): Toggle cell blocking
  ```

### Cell System (gameboard.gd)
- Uses Vector2i coordinates
- Cell size: 32x32 pixels
- Boundaries define valid range
- Index conversion for pathfinding:
  ```
  cell_to_index(): Convert cell to unique ID
  index_to_cell(): Convert ID back to cell
  pixel_to_cell(): Convert world position to cell
  cell_to_pixel(): Convert cell to world position
  ```

### Map Boundaries (debug_map_boundaries.gd)
- Visual boundary representation in editor
- Customizable appearance:
  ```
  boundary_color: Color for lines
  line_width: Width of boundary lines
  ```
- Runtime boundary validation

## Key Features

### Cell Management
- Position snapping to grid
- Pixel-to-cell conversion
- Adjacent cell detection
- Boundary validation

### Pathfinding
- A* implementation
- Blocked cell handling
- Adjacent path support
- Batch operations for efficiency

### Physics Integration
The gameboard system interacts with Godot's physics engine to understand the layout and occupancy of the grid. This information is crucial for systems like pathfinding. For a detailed explanation of the project's collision layers, see [Collision System (collision.md)](collision.md).

Key ways physics layers are typically used in conjunction with the gameboard:

- **Layer 0x1 (Gamepiece):**
    - Used to detect the presence of dynamic entities (gamepieces) on grid cells.
    - When a gamepiece that blocks movement occupies a cell, that cell's corresponding point in the `Pathfinder` is often marked as disabled (blocked) using `Pathfinder.block_cell()`. This prevents other gamepieces from pathing through it.
    - Gamepieces also use this layer for their own collision avoidance or detection.

- **Layer 0x2 (Terrain):**
    - Used during map initialization to determine which cells are inherently unpathable due to static obstacles (e.g., walls, rocks).
    - The `Pathfinder` is typically initialized with a list of cells deemed pathable after considering this terrain layer. Cells containing terrain obstacles are excluded from the pathfinding graph.

- **Layer 0x4 (Click):**
    - Primarily used by the UI/input system to detect clicks on gamepieces or specific interactive elements on the gameboard.

**Collision Shapes and Grid Alignment:**
To ensure consistency between the logical grid representation and the physics world:
- Collision shapes for terrain obstacles are generally designed to align with the grid cells (e.g., a 32x32 shape for a 32x32 cell).
- Gamepieces that occupy cells for pathfinding purposes also typically have collision shapes that represent their footprint on the grid.

This integration allows the logical gameboard state (e.g., which cells are blocked in `Pathfinder`) to be updated based on real-time physics interactions.

### Camera System (field_camera.gd)
```
Input Handling:
├── Actions (_unhandled_input)
│   ├── drag_camera: Start/end panning
│   ├── zoom_in/out: Adjust view scale
│   └── anchor_camera: Lock to gamepiece
└── Motion (_input)
    └── Mouse motion during drag

Priority Flow:
1. UI _gui_input gets mouse events over UI
2. Camera _input handles drag motion
3. Camera _unhandled_input gets remaining events

Key Properties:
- anchored: bool (follow gamepiece)
- drag_point: Vector2 (pan reference)
- zoom: Vector2 (view scale)
```

## Usage

### Setup
```
Required Configuration:
- Valid boundary rect (Rect2i)
- Cell size: 32x32 pixels
- Physics layer masks
- Pathable cells array
```

### Common Operations
```
Movement:
1. Validate cell in bounds
2. Check cell not blocked
3. Get path if valid
4. Handle empty paths

Blocking:
1. Use block_cell() for single updates
2. Use set_blocked_cells() for batch updates
3. Update pathfinding after changes
```
