# NPC Simulation Documentation

## Overview

A 2D NPC simulation built with Godot, where NPCs interact with items and navigate a game world. Features include:
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
   - ui.md: User interface

3. Entity Systems
   - npc.md: NPC behavior and needs
   - items.md: Interactive objects
   - interaction.md: Entity interactions

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
│   │   ├── Controller: Manages NPC needs and executes actions.
│   │   ├── Client Layer: Connects to the decision-making backend.
│   │   └── Backend: Handles NPC decision logic (e.g., an MCP server).
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
