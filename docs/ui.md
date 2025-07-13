# UI System

The game's UI system provides real-time information about NPCs, items, and interactions through a combination of persistent interface elements and dynamic floating windows.

## Quick Start

- **Click** on any NPC or item to see its information in the bottom panel
- **Hover** over entities to see visual highlighting
- **Press Space** to anchor the camera to the selected NPC  
- **Drag** floating conversation windows by their title bars
- **Press `** (backtick) to open the debug console

## Documentation

The UI system documentation is organized into focused topics:

- **[Overview](ui/overview.md)** - Understanding the UI system architecture
- **[Panel System](ui/panels.md)** - Creating and managing UI panels
- **[BottomUI](ui/bottom_ui.md)** - The main interface container
- **[UIElementProvider](ui/element_provider.md)** - Dynamic UI element creation
- **[UIRegistry](ui/registry.md)** - Behavior management and state tracking
- **[Behavior System](ui/behaviors.md)** - Visual feedback and interactions
- **[Floating Windows](ui/floating_windows.md)** - Draggable interaction panels
- **[Link System](ui/links.md)** - Clickable text within panels
- **[Debug Console](ui/debug_console.md)** - Developer tools

## Key Features

**Dynamic Content** - UI panels are created based on entity type and components. Select an NPC with needs and you'll see a needs panel. Select an item with consumable properties and you'll see nutrition information.

**Event-Driven Updates** - The UI responds to game events rather than constantly polling. This keeps the interface responsive while minimizing performance impact.

**Consistent Behaviors** - Visual feedback like hover highlighting and click selection work the same way across all entities, managed by a central behavior system.

**Persistent Information** - The bottom panel always shows the current time and position, while floating windows persist even after interactions end.

## Common Tasks

### Adding a New Panel Type

1. Create a panel scene extending `EntityPanel` or `InteractionPanel`
2. Define when it should appear (entity type, components, etc.)
3. Register it with `UIElementProvider`
4. The panel will automatically appear when appropriate

### Creating Visual Feedback

1. Extend `BaseUIBehavior` for your custom behavior
2. Define a `UIBehaviorTrigger` for when it activates
3. Register in `UIBehaviorConfig`
4. The behavior executes automatically on matching events

### Debugging UI Issues

- Use the debug console to check entity states
- Enable UI debug logging in project settings
- Check UIRegistry state for active behaviors
- Verify panel compatibility with `is_compatible_with()`

## Architecture Principles

The UI system follows several key principles:

**Separation of Concerns** - UI display logic is separate from game logic. Panels observe and react to game state rather than controlling it.

**Component-Based** - Entities provide their own UI through components. This allows new entity types to have appropriate UI without modifying core systems.

**Event-Driven** - UI elements respond to events rather than polling. This improves performance and ensures UI stays synchronized.

**Type Safety** - The system uses strongly-typed events and structured data throughout, catching errors at compile time rather than runtime.