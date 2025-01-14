# NPC Simulation Documentation

## Overview

A 2D NPC simulation built with Godot 4.3 where NPCs interact with items and navigate a game world. Features include:
- Needs-driven NPC behavior
- Component-based item system
- Grid-based movement and pathfinding
- Event-driven architecture

## Getting Started

1. First Steps
   - See getting-started.md for setup and quick start
   - Follow godot-tutorial.md for a hands-on example

2. Core Systems
   - gameboard.md: Grid and pathfinding system
   - gamepiece.md: Base entity framework
   - collision.md: Physics and detection
   - events.md: Communication system

3. Entity Systems
   - npc.md: NPC behavior and needs
   - items.md: Interactive objects
   - interaction.md: Entity interactions
   - ui.md: Interface components

## System Architecture

### Core Systems
```
Field (field.gd)
├── Gameboard: Grid management
├── Gamepiece: Entity base
└── Events: Communication
```

### Entity Types
```
Gamepiece Base
├── NPCs: Need-driven actors
└── Items: Interactive objects
```

### Component System
```
Components
├── Base: Core functionality
└── Specialized: Item behaviors
```

## Development

### Key Concepts
1. Component-based design
2. Event-driven communication
3. Grid-based movement
4. Need-based behavior

### Documentation Map
```
docs/
├── Setup
│   ├── getting-started.md
│   └── godot-tutorial.md
├── Meta
│   └── style_guide.md
├── Core Systems
│   ├── gameboard.md
│   ├── gamepiece.md
│   ├── collision.md
│   └── events.md
├── Entities
│   ├── npc.md
│   ├── items.md
│   └── interaction.md
└── Interface
    └── ui.md
```

For implementation details, see the corresponding documentation files.
