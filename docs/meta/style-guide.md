# Documentation Style Guide

## Core Principles

1. Every word must be useful
   Documentation should be concise and purposeful, focusing on what developers need to know to effectively use and maintain the system. Remove any fluff or redundant explanations that don't add value.

2. Use diagrams for structure
   Visual representations help developers quickly understand system organization and relationships. Use ASCII diagrams to show hierarchies and connections.
   ```
   System
   ├── Component A (file.gd) - purpose
   ├── Component B (file.tscn) - purpose
   └── Component C (file.gd) - purpose
   ```

3. Focus on function level
   Documentation should explain what components do and how they integrate, rather than implementation details. Show the key configurations and parameters that developers need to work with the system.

4. Include critical details
   Document important constants and configurations that affect system behavior. Reference source files to help developers locate implementations.

## Document Structure

1. Overview
   Start with a clear explanation of the system's purpose and how it fits into the larger application. List core components and their roles to give readers immediate context.

2. Components
   For each major component, explain its purpose, responsibilities, and how it interacts with other parts of the system. Focus on the public interface rather than internal details.

3. Setup Requirements
   Provide clear instructions for adding the system to a scene. Include required nodes, configuration values, and common usage patterns to help developers get started quickly.

## Common Mistakes

1. Code Dumps
   - ❌ Copying implementation code
   - ✅ Describing function purpose and parameters

2. Abstraction Level
   - ❌ Too high: "Manages state changes"
   - ✅ Specific: "Tracks entity position and handles collisions"

3. Missing Context
   - ❌ Listing properties without purpose
   - ✅ Explaining why and how properties are used

4. Redundant Information
   - ❌ Repeating obvious details
   - ✅ Focusing on non-obvious requirements

## Examples

### Good Component Description
```
CollisionComponent
- Handles physics interactions between entities.
- Uses collision layers for filtering.
- Emits `body_entered(body: Node)` signal when a physics body enters its area.
  - Purpose: Allows other systems to react to new overlaps.
  - Consumed by: Typically by the parent entity's script to detect specific interactions.
- Emits `body_exited(body: Node)` signal when a physics body exits its area.
  - Purpose: Allows tracking of when overlaps end.
  - Consumed by: Similar to `body_entered`, often by the parent entity to manage state related to overlaps.
- Requires CollisionShape2D child node for defining its detection area.
```

### Good Setup Description
```
Required Nodes:
- AnimationPlayer with idle animation
- Sprite with proper texture/frames
- ClickArea for interaction detection
- CollisionArea for movement blocking

Physics Layers:
1: Player
2: Environment
3: Interactables
4: Triggers
```

### Good Integration Description
```
Signal Flow:
1. Component emits event
2. Manager processes event
3. System updates state
4. UI refreshes display
```

## Additional Guidelines

1. Visual Hierarchy
   Use consistent heading levels and formatting to organize content logically. Keep sections focused and atomic, ordering from most to least important.

2. Technical Accuracy
   Verify all documented behaviors and configurations. **Always consult the relevant source code files when documenting technical details (e.g., class members, function signatures, configuration options) to ensure the documentation accurately reflects the implementation.** Test setup instructions to ensure they work as described. Keep documentation synchronized with code changes.

3. Cross-References
   Link related systems and note dependencies clearly. Show integration examples that demonstrate how components work together in practice.

4. Maintenance
   Regularly review and update documentation as the codebase evolves. Remove outdated information and clarify sections that users find confusing.
