# UI System Overview

The UI system displays game information through panels, provides visual feedback for interactions, and responds to player input. It's event-driven, component-based, and designed for extensibility.

## Quick Navigation

### Core Documentation
- **[Panel System](panels.md)** - Creating UI panels that display entity/interaction data
- **[Behavior System](behaviors.md)** - Visual feedback like highlighting and hover effects  
- **[BottomUI](bottom_ui.md)** - Main interface container with tabs and status bar
- **[UIRegistry](ui_registry.md)** - Central coordinator for behaviors and state tracking

### Key Concepts
- **Entity Focus** - Click entities to display their info in the bottom panel
- **Dynamic Panels** - UI adapts based on entity type and components
- **Visual Feedback** - Hover highlighting, interaction lines, state indicators
- **Event-Driven** - UI reacts to game events rather than polling

## Architecture Map

```
UI System
├── Display Layer (what players see)
│   ├── BottomUI - Main interface with tabs and status
│   ├── Panels - Entity info, needs, interactions
│   └── Floating Windows - Conversations, complex interactions
│
├── Visual Feedback Layer (how things react)
│   ├── HighlightManager - Sprite highlighting
│   ├── InteractionLineManager - Lines between participants
│   └── Behaviors - Hover effects, click responses
│
├── Coordination Layer (how it all connects)
│   ├── UIRegistry - Routes events to behaviors
│   ├── UIElementProvider - Creates panels dynamically
│   └── EventBus - Delivers game events to UI
│
└── Components (reusable pieces)
    ├── UILink - Clickable entity names
    ├── Panels - Base classes for display
    └── Behaviors - Visual feedback modules
```

## Key Systems

### UIRegistry (`/src/common/ui_registry.gd`)
Central coordinator that connects game events to UI responses. When something happens in the game, UIRegistry finds the right behaviors to execute.

### HighlightManager (`behaviors/visual_effects/highlight_manager.gd`)  
Manages entity sprite highlighting with priority-based color blending. Multiple systems can highlight the same entity without conflicts.

### InteractionLineManager (`/src/field/interaction_line_manager.gd`)
Draws and manages lines between interaction participants (e.g., conversation lines). Works with HighlightManager for coordinated visual feedback.

### UIElementProvider (`ui_element_provider.gd`)
Factory that creates appropriate UI panels based on entity type and components. No hardcoding - new components automatically get UI if they provide panels.

## Common Tasks

### "I want to add a new UI panel"
→ See [Panel System](panels.md)

### "I want to add hover/click effects"  
→ See [Behavior System](behaviors.md)

### "I want to make entity names clickable"
→ Use UILink: `UILink.entity(entity_id, name).to_bbcode()`

### "I want to safely reference entities"
→ Use EntityRegistry: `EntityRegistry.get_entity(entity_id)`

### "I want to highlight something"
→ Use HighlightManager: `HighlightManager.highlight(entity_id, source, color, priority)`

## Design Principles

1. **Event-Driven** - React to game events, don't poll for changes
2. **Component-Based** - Entities bring their own UI via components
3. **Separation of Concerns** - UI observes game state, doesn't control it
4. **Extensible** - Add new panels/behaviors without modifying core systems
5. **Type-Safe** - Use strongly-typed events and structured data

## Directory Structure

```
/src/ui/
├── behaviors/          # Visual feedback modules
│   ├── visual_effects/ # Highlighting, effects
│   └── triggered/      # Event-triggered behaviors
├── components/         # Reusable UI pieces
├── panels/            # Information displays
└── [core files]       # BottomUI, providers, etc.

/src/common/
├── ui_registry.gd     # Central coordinator
└── entity_registry.gd # Safe entity lookups

/src/field/
└── interaction_line_manager.gd  # Line drawing
```