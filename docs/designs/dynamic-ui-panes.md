# Dynamic UI Panes Design

## Overview
A flexible UI system that dynamically shows different information panels based on the selected gamepiece and its components.

## Core Features
- Dynamic panel creation based on gamepiece type
- Priority-based panel ordering
- Component-specific panels
- Automatic panel lifecycle management

## Panel Types

### Info Panels (Priority 0)
Always shown first when compatible:
- NpcInfoPanel: Shows NPC traits
- ItemInfoPanel: Shows basic item info

### NPC Panels (Priority 1)
Shown for NPCs:
- NeedsPanel: Shows need bars
- WorkingMemoryPanel: Shows memory state

### Component Panels (Priority 1)
Shown based on item components:
- ConsumablePanel: Shows usage info
- NeedModifyingPanel: Shows rate changes
- SittablePanel: Shows occupancy state

## Architecture

### Base Panel (gamepiece_panel.gd)
```
Properties:
├── update_interval: How often to update (30fps default)
├── current_controller: Active controller reference
└── time_since_update: Update tracking

Methods:
├── is_compatible_with(): Type checking
├── _setup(): Initial configuration
├── _show_default_text(): Empty state
├── _show_invalid_text(): Error state
└── _update_display(): Content refresh

Events:
└── FOCUSED_GAMEPIECE_CHANGED: Selection updates
```

### Tab Container (tab_container.gd)
```
Management:
├── Panel Creation
│   ├── Load panel scene
│   ├── Check compatibility
│   └── Initialize state
├── Panel Sorting
│   ├── Priority groups (0-1)
│   └── Alphabetical within groups
├── Panel Activation
│   ├── Process only active tab
│   └── Pause other tabs
└── Panel Cleanup
    ├── Remove old panels
    └── Free resources
```

## Implementation Details

### Panel Creation Flow
1. Gamepiece focused
2. Remove existing panels
3. Get gamepiece controller
4. For each panel scene:
   - Load and instantiate
   - Check compatibility
   - Configure if compatible
   - Free if incompatible
5. Sort compatible panels
6. Add to container
7. Set tab titles
8. Pass focus event

### Update Cycle
1. Panel activated
2. Process enabled
3. Time tracked
4. Display updated at interval
5. Panel deactivated
6. Process disabled

### Component Integration
- Components can be nested at any depth
- Panels use type checking for compatibility
- Component panels show specific info
- Updates reflect component state

## Best Practices

### Panel Implementation
1. Extend GamepiecePanel
2. Override compatibility check
3. Implement display methods
4. Handle state updates

### Component Panels
1. Check component existence
2. Get component reference
3. Show component state
4. Update on changes

### Error Handling
1. Check controller validity
2. Handle missing components
3. Show appropriate messages
4. Clean up resources

## Future Improvements
1. Panel persistence between selections
2. Custom panel ordering
3. Panel state saving
4. More component panels
