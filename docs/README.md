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
├── Gameboard: Grid and pathfinding
├── Gamepiece: Entity framework
└── Events: Global communication bus
```

### Entity Architecture
```
Gamepiece Base (gamepiece.gd)
├── NPCs (npc_controller.gd)
│   ├── Three-tier architecture
│   │   ├── Controller: Needs and actions
│   │   ├── Client: Backend interface
│   │   └── Backend: Decision making
│   ├── Need System
│   │   ├── Values: 0-100 range
│   │   └── Types: hunger, energy, etc
│   └── Event-driven updates
└── Items (item_controller.gd)
    ├── Component-based design
    └── Interaction system
```

### Event Architecture
```
Event System
├── Field Events: Global dispatch
├── NPC Events
│   ├── Interaction lifecycle
│   ├── Observations
│   └── State updates
└── Response System
    ├── Action definitions
    └── Status handling
```

## Development

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
