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

## System Architecture Overview

The simulation is built upon several key interconnected systems:

*   **Core Infrastructure:**
    *   **Gameboard (`gameboard.md`):** Manages the grid, cell-based positioning, and pathfinding.
    *   **Gamepiece (`gamepiece.md`):** The base framework for all dynamic entities in the world, providing common functionalities like movement and component management.
    *   **Events (`events.md`):** A global system for dispatching and handling various game events, enabling decoupled communication between different parts of the simulation.
    *   **Collision (`collision.md`):** Handles physics-based detection and interactions.

*   **Entity Systems:**
    *   **NPCs (`npc.md`):** Manages Non-Player Characters, including their needs, decision-making processes (using a three-tier controller-client-backend architecture), and interactions.
    *   **Items (`items.md`):** Defines interactive objects within the world, built with a flexible component-based design.
    *   **Interaction (`interaction.md`):** Governs how NPCs and items (or other entities) engage with each other.

*   **User Interface (`ui.md`):** Provides visual feedback and controls for observing and interacting with the simulation.

For a more detailed breakdown of the overall architecture and how these systems fit together, please refer to the [Getting Started Guide](getting-started.md). Specific details for each system can be found in their respective documentation files linked above.
