# NPC Simulation Development Guide

## Running & Testing
- Open project in Godot 4.3
- Open main.tscn and run with F5
- Right-click drag to pan camera, mouse wheel to zoom
- Press A to anchor camera to selected NPC

## Project Structure
- src/common/ - Events, globals, shared utilities
- src/field/ - Game systems (gamepieces, NPCs, items)
- src/ui/ - Interface components and panels

## Code Style Guidelines
- Classes: PascalCase (GamepieceController)
- Variables/Functions: snake_case (current_interaction)
- Constants: SCREAMING_SNAKE_CASE (MAX_NEED_VALUE)
- Private members: underscore prefix (_vision_manager)
- Signals: snake_case (need_changed)

## Development Patterns
- Component-based architecture with event-driven communication
- Event handling: Connect in _ready(), type-check events, handle appropriately
- Item Creation: Create ItemConfig resource, configure properties, add component configs
- NPC System: Controller handles decisions, Client manages communication, Backend determines actions
- Always implement proper resource cleanup
- Use get_controller() for accessing component controllers

## Physics Layers
1: Player
2: Environment
3: Interactables
4: Triggers