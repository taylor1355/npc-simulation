# Gameboard System

## Core Components

### Pathfinder (`src/field/gameboard/pathfinder.gd`)
The `Pathfinder` class extends `AStar2D` to provide pathfinding capabilities using `Vector2i` cell coordinates. It works in conjunction with a `Gameboard` resource for coordinate conversions and boundary checks.

**Key Responsibilities & Features:**
*   **Initialization:** Takes an array of `pathable_cells: Array[Vector2i]` and a `Gameboard` instance. It builds an A* graph from these pathable cells, respecting the gameboard's boundaries.
*   **Path Calculation:**
    *   `get_path_cells(source_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]`: Finds the shortest path between two cells. Returns an empty array if no path exists or if cells are outside boundaries/not in the graph.
    *   `get_path_cells_to_adjacent_cell(source_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]`: Finds the shortest path to a cell adjacent to the `target_cell`.
*   **Cell Blocking Management:**
    *   `block_cell(cell: Vector2i, value: bool = true)`: Marks/unmarks a specific cell as disabled for pathfinding (e.g., if occupied by a dynamic obstacle).
    *   `set_blocked_cells(blocked: Array[Vector2i])`: Batch updates blocked cells. Cells not in the `blocked` array are unblocked.
    *   `get_blocked_cells() -> Array[Vector2i]`: Returns a list of currently blocked cells.
*   **Utility:** `has_cell(Vector2i)` checks if a cell is part of the pathfinding graph.

It relies on the associated `Gameboard` for converting `Vector2i` cells to unique IDs for `AStar2D` (via `_gameboard.cell_to_index()`) and vice-versa (`_gameboard.index_to_cell()`).

### Cell System (`assets/maps/gameboard.gd`)
The `Gameboard` class is a `Resource` that defines the grid structure of the playable area.

**Key Properties & Methods:**
*   **`boundaries: Rect2i`**: Defines the extents of the grid (default: 0,0 to 10,10). Must use positive coordinates.
*   **`cell_size: Vector2i`**: The dimensions of each grid cell in pixels (default: 16x16 pixels).
*   **Coordinate Conversion:**
    *   `cell_to_pixel(Vector2i) -> Vector2i`: Converts cell coordinates to world pixel coordinates (center of cell).
    *   `pixel_to_cell(Vector2) -> Vector2i`: Converts world pixel coordinates to cell coordinates.
    *   `cell_to_index(Vector2i) -> int`: Converts cell coordinates to a unique integer ID for pathfinding or storage. Returns `INVALID_INDEX` (-1) if outside boundaries.
    *   `index_to_cell(int) -> Vector2i`: Converts a unique ID back to cell coordinates. Returns `INVALID_CELL` (Vector2i(-1,-1)) if index is invalid.
*   **Adjacency:**
    *   `get_adjacent_cell(cell: Vector2i, direction: int) -> Vector2i`: Gets a neighboring cell in a given `Directions.Points` direction.
    *   `get_adjacent_cells(cell: Vector2i) -> Array[Vector2i]`: Returns all valid adjacent cells.
*   **Constants:** `INVALID_CELL` and `INVALID_INDEX` for out-of-bounds checks.

### Map Boundaries Visualizer (`src/field/gameboard/debug_map_boundaries.gd`)
This `@tool` script (`DebugMapBoundaries`) is a `Node2D` used in the editor to visually represent the `boundaries` of a linked `Gameboard` resource.
*   It draws a rectangle corresponding to the gameboard's pixel boundaries.
*   Appearance is customizable via `@export var boundary_color: Color` and `@export var line_width: float`.
*   It automatically hides itself when not in the editor. This helps designers see the effective playable area.

## Key Features

### Cell Management (Provided by `Gameboard`)
*   **Grid Definition:** Establishes the grid using `boundaries` and `cell_size`.
*   **Coordinate Systems:** Manages conversions between cell coordinates, pixel coordinates, and unique cell indices.
*   **Adjacency Information:** Provides methods to find adjacent cells.
*   **Boundary Checks:** Implicitly used in `cell_to_index` and `get_adjacent_cell` to ensure validity.

### Pathfinding (Provided by `Pathfinder`)
*   **A* Based:** Leverages Godot's `AStar2D` for path calculations on the grid.
*   **Dynamic Obstacles:** Supports dynamically blocking and unblocking cells for pathfinding (e.g., for moving gamepieces).
*   **Adjacent Target Paths:** Can find paths to cells next to a target, useful for interactions.

### Physics Integration
The gameboard system interacts with Godot's physics engine to determine grid cell occupancy and passability, crucial for pathfinding and gamepiece interactions. For details on collision layers, see [Collision System (collision.md)](collision.md).

**Typical Usage:**
*   **Static Terrain (Layer `0x2`):** During initialization, cells containing static terrain obstacles (detected via physics queries) are excluded when providing `pathable_cells` to the `Pathfinder`.
*   **Dynamic Gamepieces (Layer `0x1`):**
    *   When a gamepiece that blocks movement occupies a cell, `Pathfinder.block_cell()` is used to mark that cell as temporarily unpathable.
    *   Gamepieces use this layer for their own collision detection.
*   **Click/Interaction (Layer `0x4`):** Used by UI/input systems to detect interactions on the gameboard.

**Grid-Physics Alignment:** Collision shapes for terrain and gamepieces are typically designed to align with the grid cells (e.g., a 16x16 shape for a 16x16 cell if using default `cell_size`) to ensure consistency between the logical grid and the physics world.

### Camera System (`src/field/field_camera.gd`)
The `FieldCamera` (extends `Camera2D`) provides specialized camera behavior for navigating the game field, constrained by the `Gameboard` boundaries.

**Key Features & Behavior:**
*   **Boundary Constraints:** The camera's movement is limited to the extents defined by the linked `Gameboard` resource. The `_on_viewport_resized()` method dynamically calculates these limits (`limit_left`, `limit_right`, `limit_top`, `limit_bottom`) based on the gameboard's pixel dimensions and the current viewport size. If the gameboard is smaller than the viewport, the camera will be centered on the gameboard along the constrained axis/axes.
*   **Anchoring:**
    *   Can be anchored to a specific `Gamepiece` via the `gamepiece` export or by setting the `anchored: bool` property to `true`.
    *   When anchored, it follows the `gamepiece.camera_anchor` node by setting its `remote_path`.
    *   The `anchor_camera` input action re-enables anchoring.
*   **Panning:**
    *   Triggered by the `drag_camera` input action (which sets `anchored` to `false` and records the `drag_point`).
    *   Mouse motion (handled in `_input`) while `drag_point` is active pans the camera.
*   **Zooming:**
    *   Handled by `zoom_in` and `zoom_out` input actions, which call `zoom_by(delta: float)`.
    *   This method adjusts the camera's inherited `zoom` property (clamped to a min/max range).
*   **Input Handling Priority:** Follows standard Godot input flow. UI elements typically consume input first (`_gui_input`). The camera then handles drag motion in `_input` if active, and other camera-specific actions (like starting a drag, zooming, anchoring) in `_unhandled_input`.

**Key Properties (managed by the script):**
*   `gameboard: Gameboard` (Export): The gameboard resource defining boundaries, used for limit calculations.
*   `gamepiece: Gamepiece` (Export): The optional gamepiece to anchor to.
*   `anchored: bool`: If `true`, camera attempts to follow the `gamepiece`.
*   `drag_point: Variant`: Stores mouse position during panning (is a `Vector2` when dragging, `null` otherwise).
(The `zoom: Vector2` property is inherited from `Camera2D` and manipulated by this script.)

## Usage

### Setup
Setting up the gameboard system involves several parts:

1.  **`Gameboard` Resource:**
    *   Create or load an `assets/maps/gameboard.gd` resource.
    *   Configure its `boundaries` (e.g., `Rect2i(0, 0, 50, 30)`) and `cell_size` (e.g., `Vector2i(16, 16)`).
2.  **`Pathfinder` Instance:**
    *   Instantiate `Pathfinder` typically at runtime.
    *   Provide it with an array of `pathable_cells` ( `Vector2i` coordinates representing initially walkable cells, often determined by checking against a terrain tilemap or physics layer).
    *   Pass the configured `Gameboard` resource to its constructor.
3.  **Physics Layers & Collision Shapes:**
    *   Configure physics layers in Project Settings (e.g., for Gamepieces, Terrain).
    *   Ensure gamepieces and terrain elements have appropriate `CollisionShape2D`s aligned with their grid representation.
4.  **(Optional) `DebugMapBoundaries`:**
    *   In your main scene, add a `DebugMapBoundaries` node and link its `gameboard` export to your `Gameboard` resource to visualize boundaries in the editor.

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
