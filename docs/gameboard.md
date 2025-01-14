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
- Layer 0x1: Gamepieces (entities)
- Layer 0x2: Terrain (obstacles)
- Layer 0x4: Click detection
- Collision shapes match cell size (32x32)

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
