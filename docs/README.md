# NPC Simulation Documentation

## Overview

A 2D NPC simulation built with Godot 4.3+, where NPCs autonomously interact with items and each other based on their needs. The project features:
- Needs-driven NPC behavior with backend decision-making
- Component-based architecture using the EntityComponent system
- Grid-based movement with A* pathfinding
- Event-driven communication via EventBus
- Multi-party interactions including conversations
- Observation system for structured state reporting

## Getting Started

1. **Setup and Running**
   - See [getting-started.md](getting-started.md) for installation and quick start
   - Use mock backend for testing without MCP server
   - Press ` (backtick) for debug console

2. **Core Systems**
   - [gameboard.md](gameboard.md): Grid management and pathfinding
   - [gamepiece.md](gamepiece.md): Base entity framework with component support
   - [collision.md](collision.md): Physics layers and detection
   - [events.md](events.md): EventBus communication system

3. **Entity Systems**
   - [npc.md](npc.md): NPC behavior, state machine, and observation system
   - [items.md](items.md): Component-based interactive objects
   - [interaction.md](interaction.md): Bid-based interaction system with factories
   - [conversation.md](conversation.md): Multi-party conversation protocol

4. **User Interface**
   - [UI System](ui/README.md): UI architecture and components
   - [UI Documentation](ui/): Detailed UI subsystem docs

## Architecture Highlights

### Three-Tier NPC System
1. **Controller**: Manages state machine, movement, and action execution
2. **Client**: Handles backend communication (GDScript + C# bridge)
3. **Backend**: Makes decisions based on observations (MCP server or mock)

### Component System
- **EntityComponent**: Unified base for items and NPCs
- **PropertySpec**: Type-safe property configuration
- **InteractionFactory**: Pattern for creating interactions
- Items and NPCs gain functionality through modular components

### Interaction System
- **InteractionBid**: Request/response pattern for starting interactions
- **MultiPartyBid**: Protocol for group interactions like conversations
- **InteractionContext**: Polymorphic architecture for unified single/multi-party interaction handling
- **Streaming interactions**: Support for ongoing observations
- **InteractionEvents**: Comprehensive lifecycle event system
- Factory pattern enables flexible interaction creation

### Observation System
NPCs gather and report structured observations:
- **CompositeObservation**: Bundles multiple observation types
- **Core observations**: Needs, vision, status, conversations
- **Event observations**: Interaction lifecycle tracking
- Formatted and sent to backend for decision-making

## Key Patterns

### Event-Driven Communication
```gdscript
# Direct signal connection
EventBus.gamepiece_clicked.connect(_on_gamepiece_clicked)

# Generic event handling
EventBus.event_dispatched.connect(
    func(event: Event):
        if event.is_type(Event.Type.NPC_NEED_CHANGED):
            handle_need_change(event)
)
```

### Component Configuration
```gdscript
extends ItemComponent

func _init():
    PROPERTY_SPECS["my_property"] = PropertySpec.new(
        "my_property",
        TypeConverters.PropertyType.FLOAT,
        1.0,
        "Description"
    )

func _create_interaction_factories() -> Array[InteractionFactory]:
    return [MyInteractionFactory.new(self)]
```

## Development Workflow

1. **Adding New Items**: Create ItemConfig resource, add components, configure properties
2. **Creating NPCs**: Configure needs, components, and backend connection
3. **New Interactions**: Implement InteractionFactory, define lifecycle handlers
4. **Testing**: Use mock backend for predictable behavior

## Current Limitations

See technical debt notes in individual documentation files and CLAUDE.md for known issues and planned improvements.