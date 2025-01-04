# NPC Simulation Documentation

## Project Overview

This is a 2D NPC simulation game built with Godot where NPCs can interact with items and navigate a game world. The project implements pathfinding, needs systems, and item interactions.

## Core Systems

### Field System
The field system (`src/field/field.gd`) manages the game world, including:
- Tile-based movement
- Cursor interaction
- Entity management (NPCs and items)

### Gameboard System
Located in `src/field/gameboard/`, handles:
- Pathfinding (`pathfinder.gd`)
- Map boundaries (`debug_map_boundaries.gd`)
- Collision detection

### Gamepiece System
Base system for all entities (`src/field/gamepieces/`):
- Base gamepiece class with common functionality
- Animation system
- Controller system for behavior

## Key Components

### NPCs
NPCs (`src/field/npcs/`) are the main actors in the simulation:
- Controlled by `npc_controller.gd`
- Have needs and desires
- Can interact with items
- Include vision system (`vision_manager.gd`)

### Items
Items (`src/field/items/`) are interactive objects:
- Have various components for different behaviors

### UI System
The UI system (`src/ui/`) provides:
- Need bars to display NPC states
- Interactive elements
- Status displays

### Common Utilities
Common utilities (`src/common/`) provide:
- Direction handling
- Collision detection
- Global state management
- Event system
- Music system

## Usage Guide

### Adding New NPCs
1. Instance the NPC scene (`src/field/npcs/npc.tscn`)
2. Configure NPC controller parameters
3. Set up needs and behaviors

### Creating New Items
1. Create a new scene inheriting from gamepiece
2. Add required components (e.g., consumable)
3. Configure interaction parameters

### Extending the Map
1. Use the tilemap system
2. Configure collision layers
3. Update pathfinding grid

### Adding New Interactions
1. Create new interaction script
2. Implement interaction logic
3. Register with interaction system

## Technical Details

### Pathfinding
The system uses A* pathfinding implemented in `pathfinder.gd` with:
- Obstacle avoidance
- Efficient path calculation
- Path smoothing

### Animation System
Gamepiece animations (`src/field/gamepieces/animation/`) support:
- Static animations
- Walking animations
- Click area handling

### Controller System
The controller system (`src/field/gamepieces/controllers/`) enables:
- AI behaviors
- Path following
- Interaction handling

### Event System
The field events system (`src/common/field_events.gd`) manages:
- Inter-entity communication
- State changes
- UI updates

## Best Practices

1. Always extend from appropriate base classes:
   - Use gamepiece for entities
   - Implement proper controllers
   - Follow component pattern for items

2. Use the event system for communication:
   - Avoid direct references
   - Maintain loose coupling
   - Handle cleanup properly

3. Follow the established patterns:
   - Component-based design
   - Event-driven architecture
   - Resource management

4. Maintain separation of concerns:
   - Keep controllers focused
   - Use components for specific behaviors
   - Leverage the common utilities
