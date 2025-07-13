# BottomUI System

The BottomUI provides the main interface at the bottom of the screen, combining tabbed panels for entity information with a persistent status bar showing time and position.

## Design

The BottomUI creates a cohesive interface that stays anchored to the bottom of the screen while the game camera moves around. It consists of two main sections:

**Tab Section** - Dynamic tabs that change based on what entity you've selected. Click an NPC and you'll see tabs for their info, needs, and working memory. Click an item and you'll see tabs for its properties and components.

**Status Bar** - Always visible beneath the tabs, showing the current simulation time, date, and grid coordinates. This gives players constant awareness of when and where they are in the game world.

## Architecture

The BottomUI orchestrates several components:

```
BottomUI (PanelContainer)
└── VBoxContainer
    ├── TabSection
    │   └── TabContainer - Managed by tab_container.gd
    └── StatusSection
        └── StatusLabel - Time and position display
```

The `BottomUI` class manages the overall container and status updates. The `TabContainer` handles the dynamic panel creation and switching.

## Status Bar

The status bar displays information in a clean, readable format:

```
Mar 1, Year 1  •  6:00 AM  •  Pos (x,y): 10, 15
```

It updates through two mechanisms:

**Time updates** come from the SimulationTime system. The BottomUI subscribes to receive updates 10 times per second, formatting the time and date for display.

**Position updates** come from cell highlighting events. Whenever the mouse hovers over a new grid cell, the coordinates update to show that position.

## Tab Management

The TabContainer within BottomUI creates tabs dynamically based on the selected entity:

1. **Selection changes** trigger a `FOCUSED_GAMEPIECE_CHANGED` event
2. **TabContainer** asks UIElementProvider for panels compatible with the entity
3. **Old tabs** are removed and their panels deactivated
4. **New tabs** are created, sorted by priority, and activated

This process happens quickly enough that tab switches feel instantaneous to the player.

## Integration

The BottomUI integrates with several game systems:

**SimulationTime** provides the current game time and date. The UI subscribes with a specific ID and properly unsubscribes when destroyed.

**EventBus** delivers cell highlighting events for coordinate updates and focus change events for tab updates.

**UIElementProvider** supplies the appropriate panels for each entity type, ensuring the right tabs appear for each selection.

## Usage

The BottomUI is part of the main UI scene and requires no special setup. It initializes itself and begins working as soon as the scene loads.

To access it from other scripts:

```gdscript
# Get the BottomUI instance
var bottom_ui = get_tree().get_first_node_in_group("bottom_ui")

# Access the TabContainer if needed
var tabs = bottom_ui.get_tab_container()
```

## Visual Design

The BottomUI uses consistent styling:
- **8px margins** throughout for visual consistency
- **Bullet separators** (•) between status elements
- **Single-line status** to maintain a compact footprint
- **Professional appearance** with proper Panel styling

The status bar connects visually to the tab area above it, creating a unified interface block rather than separate floating elements.

## Performance

The BottomUI is designed for efficiency:

- **Single time subscription** shared between all status elements
- **Event-driven updates** rather than per-frame polling  
- **Cached formatting** to avoid recreating strings unnecessarily
- **Minimal rebuilding** when tabs change

The 10Hz update rate for time provides smooth updates without excessive processing.

## Extending the Status Bar

To add new information to the status bar:

1. Add your data source (event subscription, direct reference, etc.)
2. Update `_update_status_display()` to include your information
3. Use bullet separators to maintain visual consistency
4. Keep the display on a single line

Example adding player health:
```gdscript
status_display.text = "%s  •  %s  •  Pos: %d, %d  •  Health: %d" % [
    date_str, time_str, _current_cell.x, _current_cell.y, player_health
]
```

## Common Issues

**Tabs not updating** - Ensure the entity has UIElementProvider panels registered for its type and components.

**Time not showing** - Verify SimulationTime singleton is in the project and autoloaded.

**Position stuck** - Check that cell highlighting events are being dispatched when the mouse moves.

The BottomUI provides a stable foundation for the game's interface, giving players the information they need while staying out of the way of gameplay.