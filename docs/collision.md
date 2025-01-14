# Collision System

## Core Components

### CollisionFinder (collision_finder.gd)
- Dynamic object detection through physics
- Key parameters:
  ```
  space_state: PhysicsDirectSpaceState2D
  search_radius: float (16.0, half cell)
  collision_mask: int (layer filter)
  find_areas: bool (default true)
  ```
- Usage:
  ```
  1. Get physics state
  2. Configure search params
  3. Query for collisions
  4. Process collision data
  ```

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
```
Search Process:
1. Configure query parameters:
   - Position (global coords)
   - Radius (16.0 pixels)
   - Collision mask
2. Execute physics query
3. Filter results by mask
4. Return collision data
```

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
