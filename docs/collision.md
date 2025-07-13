# Collision System

## Core Components

### CollisionFinder (`src/common/collision_finder.gd`)
The `CollisionFinder` class is a utility for dynamically detecting physics objects (both bodies and areas) within a specified radius. It's a key tool for features like gameboard cell occupancy checks or proximity detection, querying Godot's physics engine.

**Initialization & Configuration:**
`CollisionFinder` is initialized (`_init`) with:
*   `space_state: PhysicsDirectSpaceState2D`: The direct space state from the current 2D world, used for queries.
*   `search_radius: float`: Defines the radius of the circular search area (e.g., `16.0` pixels, often half a game cell).
*   `collision_mask: int`: A bitmask to filter for specific physics layers.
*   `find_areas: bool` (default `true`): If `true`, includes `Area2D`s in results; otherwise, only `PhysicsBody2D`s.

During initialization, these parameters configure a `PhysicsShapeQueryParameters2D` object. This object holds a `CircleShape2D` (using `search_radius`), the `collision_mask`, and area detection settings, and is cached for efficient repeated searches.

**Searching for Collisions:**
Its main method, `search(position: Vector2) -> Array[Dictionary]`, performs the search:
*   Takes a global `position` to center the search.
*   Updates the cached query's `transform.origin` to this position.
*   Calls `_space_state.intersect_shape()`, returning an array of dictionaries. Each dictionary represents a detected object and includes details like the `collider` and `shape` index (as per Godot's `intersect_shape` documentation).

**Usage Workflow:**
1.  Get `PhysicsDirectSpaceState2D` (e.g., `get_world_2d().direct_space_state`).
2.  Instantiate `CollisionFinder` with the space state, search radius, collision mask, and area preference.
3.  Call `search(global_position)` as needed.
4.  Process the returned collision results.
Note: Physics updates may have a one-frame detection delay.

### Physics Layers
```
Layer Configuration:
├── 0x1: Gamepiece
│   ├── Entity detection
│   ├── Movement blocking
│   └── Interaction zones
├── 0x2: Terrain
│   ├── Static obstacles
│   ├── Pathfinding blocks
│   └── Movement barriers
└── 0x4: Click
    ├── Interaction detection
    ├── Extended bounds (+2-3 pixels)
    └── Input handling
```

### Collision Areas
```
Required Shapes:
├── CollisionArea
│   ├── Layer: 0x1 (Gamepiece)
│   ├── Size: Match visual bounds
│   └── Purpose: Movement blocking
└── ClickArea
    ├── Layer: 0x4 (Click)
    ├── Size: Slightly larger
    └── Purpose: Interaction
```

## Key Features

### Object Detection
`CollisionFinder` enables precise circular area detection of physics objects (`PhysicsBody2D`s and/or `Area2D`s), a capability fundamental for mechanics like cell occupancy or proximity checks. The process involves:

*   **Pre-configured Queries:** `CollisionFinder` initializes and caches `PhysicsShapeQueryParameters2D` with a `CircleShape2D` (using its `search_radius`) and `collision_mask` for efficient, layer-specific searches.
*   **Targeted Searching:** The `search(position)` method uses these cached parameters to query the physics space at the given global `position`.
*   **Engine-Level Filtering:** The `collision_mask` ensures efficient, automatic layer filtering by Godot's physics engine during the `intersect_shape` call.
*   **Direct Collision Data:** The `search` method returns an array of dictionaries, each containing detailed collider information (e.g., the collider node, shape index) for further processing.

### Physics Integration
```
Update Flow:
1. Changes on physics tick
2. One frame delay for updates
3. Results include:
   - Collider reference
   - Shape data
   - Layer information
```

### Common Uses
```
Gamepiece System:
- Cell occupancy checks
- Movement validation
- Interaction detection

Pathfinding:
- Obstacle detection
- Valid cell checking
- Path validation

Interaction:
- Click detection
- Range checking
- Collision validation
```

## Usage

### Required Setup
```
1. Configure collision layers
2. Set up collision shapes
3. Initialize CollisionFinder
4. Handle physics updates
```

### Best Practices
```
1. Use appropriate masks
2. Check results every frame
3. Handle stale data
4. Clean up physics objects
```
