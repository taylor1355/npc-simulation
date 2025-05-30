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

3. Emphasize Purpose and Responsibilities
   Documentation should clearly explain *what* a component or system does, its primary responsibilities, and *how* it integrates with other parts of the application. Focus on the 'why' and 'what' over minute implementation details. While key configurations, parameters, or method signatures critical for usage should be included, avoid exhaustive lists of all internal properties or private methods.

4. Include critical details
   Document important constants, configurations, and public interfaces (key methods, signals, exported properties) that affect system behavior or are necessary for integration. Reference source files to help developers locate implementations.

5. Prioritize Clarity and Readability
   Strive for descriptive explanations that help a developer understand a system's role and behavior quickly. Use narrative descriptions, often supplemented by bullet points for key responsibilities or features, rather than just listing technical specifications. The goal is to provide enough detail for comprehension without overwhelming the reader. Aim for strategically concise language: be descriptive enough to convey necessary information and context, but avoid unnecessary verbosity that could increase cognitive load. If a shorter phrasing conveys the same meaning effectively, prefer it. However, do not sacrifice critical context or clarity for the sake of extreme brevity. The key is to find a balance that makes the documentation both informative and easy to digest.

## Document Structure

1. Overview
   Start with a clear explanation of the system's purpose and how it fits into the larger application. List core components and their roles to give readers immediate context.

2. Components
   For each major component, explain its purpose, responsibilities, and how it interacts with other parts of the system. Focus on the public interface rather than internal details.

3. Setup Requirements
   Provide clear instructions for adding the system to a scene. Include required nodes, configuration values, and common usage patterns to help developers get started quickly.

## Common Mistakes

1. Code Dumps or Overly Technical Listings
   - ❌ Copying large blocks of implementation code, or exhaustively listing all internal members (private methods, internal variables) without context.
   - ✅ Describing the component's overall purpose, its key public interfaces (APIs, signals, critical exported properties), and how they are intended to be used. Focus on what a consumer of the component needs to know.

2. Abstraction Level
   - ❌ Too high: "Manages state changes" (Too vague).
   - ✅ Specific: "Tracks entity position based on grid coordinates and handles collisions with static obstacles defined in the tilemap's physics layer." (Clear and informative).

3. Missing Context
   - ❌ Listing properties or methods without explaining their purpose or typical usage (e.g., "Property: `max_speed: float`").
   - ✅ Explaining why a property exists and how it influences behavior (e.g., "`max_speed: float` - Defines the maximum velocity the entity can reach. Used by the movement system to cap acceleration.").

4. Redundant Information
   - ❌ Repeating obvious details that can be inferred or are standard (e.g., "This function is a function.").
   - ✅ Focusing on non-obvious requirements, important interactions, or critical configurations.

5. Dry Specification Lists
   - ❌ Presenting information as a dry list of technical specifications (e.g., just method signatures or property names) without descriptive text explaining their role or usage.
   - ✅ Providing narrative explanations for how a component works and how its key features are used, supplemented by technical details where necessary, to aid understanding.

## Examples

### Good Component Description

**AudioPlayerComponent (`audio_player_component.gd`)**

The `AudioPlayerComponent` is responsible for managing and playing sound effects and background music for a game entity. It provides a simple interface for triggering sounds by name and can handle variations in pitch and volume.

**Key Responsibilities:**
*   **Sound Playback:**
    *   Provides a `play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0)` method to trigger specific sound effects. `sound_name` should correspond to a preloaded audio stream.
    *   Manages a collection of `AudioStreamPlayer` nodes (or a single one reused) to play sounds.
*   **Configuration:**
    *   `@export var sounds: Dictionary[String, AudioStream]` - Allows mapping sound names to `AudioStream` resources in the Inspector. This dictionary is used by `play_sound` to find the correct audio stream.
    *   `@export var default_volume_db: float = 0.0` - A baseline volume adjustment (in decibels) for sounds played through this component, applied if no specific volume is provided to `play_sound`.
*   **Integration:**
    *   Typically added as a child node to a `Gamepiece` or other scene that requires audio feedback.
    *   Other scripts call `play_sound()` on this component to trigger audio events (e.g., on collision, on item use, UI interactions).

**Usage Example (from another script):**
```gdscript
# Assuming get_node("AudioPlayerComponent") returns the component
# Play a "jump_sound" with reduced volume and slightly higher pitch.
$AudioPlayerComponent.play_sound("jump_sound", -5.0, 1.1)
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
