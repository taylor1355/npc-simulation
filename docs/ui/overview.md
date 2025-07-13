# UI System Overview

The UI system provides players with real-time information about NPCs, items, and ongoing interactions. It combines persistent interface elements at the bottom of the screen with floating windows that appear during conversations and other multi-party interactions.

## Core Concepts

The UI operates on a few key principles that shape how information is displayed:

**Entity Focus** - When you click on an NPC or item, it becomes the "focused entity" and the bottom panel updates to show relevant information. NPCs display their needs, current state, and working memory. Items show their properties and available interactions.

**Dynamic Panel Creation** - The system automatically determines which panels to show based on the entity's type and components. An NPC with needs gets a needs panel. An item with a consumable component gets a panel showing its effects. This happens without hardcoding specific entity types.

**Interaction Windows** - When NPCs start conversations or other complex interactions, floating windows appear to show the interaction's progress. These windows can be dragged around and persist even after the interaction ends, letting players review conversation history.

**Reactive Behaviors** - The UI responds to game events with visual feedback. Hovering over an NPC highlights their nameplate. Clicking opens their information panels. Starting a conversation draws lines between participants. These behaviors are configured centrally and applied consistently.

## Architecture

The UI system is built around three main components that work together:

**BottomUI** serves as the main interface container at the bottom of the screen. It displays the current simulation time and coordinates in a status bar, while tabs above show information about the selected entity. The tabs change dynamically based on what you've clicked on.

**UIElementProvider** acts as a factory for UI elements. When you select an entity, it determines which panels should appear based on that entity's type and components. It also creates floating windows for interactions when needed.

**UIRegistry** coordinates all UI behaviors and tracks the current UI state. It knows what's being hovered over, what's selected, and which windows are open. When game events occur, it finds matching behaviors and executes them.

## Panel System

All UI panels inherit from a common base that manages their lifecycle. Panels can be activated when visible and deactivated when hidden to save processing power.

**Entity panels** display information about the currently selected gamepiece. They automatically update when you click on a different entity, checking if they're compatible with the new selection. For example, a needs panel only shows for NPCs that have needs.

**Interaction panels** are tied to specific interactions rather than the focused entity. A conversation panel shows messages from all participants and continues to work even after you click away from the conversing NPCs.

## Visual Feedback

The behavior system provides consistent visual feedback across the UI:

- **Hover effects** highlight entities as you mouse over them
- **Selection indicators** show which entity is currently focused
- **Interaction visualization** draws lines between conversation participants
- **State emojis** appear above NPCs showing their current activity

These behaviors are defined once and applied everywhere, ensuring consistency across all UI elements.

## Floating Windows

Interactions that need dedicated UI space use floating windows. These windows:
- Can be dragged by their title bar
- Stay within screen bounds
- Persist after interactions end (marked as "historical")
- Support multiple windows open simultaneously

The most common use is conversation panels, which show a chat-like interface for multi-party NPC conversations.

## Developer Tools

The debug console (toggle with backtick) provides runtime commands for testing:
- Switch between AI backends
- View available commands with `help`
- Clear console output
- Extensible for additional development needs

## Integration with Game Systems

The UI system integrates deeply with the game's event system. Rather than polling for changes, UI elements respond to events:

1. **Entity clicked** → Focus changes → Tabs update
2. **Interaction started** → Window opens → Panel connects to interaction
3. **State changed** → Panel content refreshes
4. **Hover started** → Visual highlight applied

This event-driven approach keeps the UI responsive while minimizing performance impact.

## Next Steps

- To create custom panels, see [Panel System](panels.md)
- For visual effects and behaviors, see [Behavior System](behaviors.md)
- To understand the bottom interface, see [BottomUI](bottom_ui.md)
- For floating windows, see [Floating Windows](floating_windows.md)