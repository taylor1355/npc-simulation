# Godot Implementation Tutorial: NPC Simulation Systems

## Project Structure

The project follows a component-based architecture with the following structure:

```
src/
├── common/          # Shared utilities and systems
│   ├── collision_finder.gd
│   ├── directions.gd
│   ├── field_events.gd
│   └── globals.gd
├── field/          # Core game systems
│   ├── field.gd    # Main field system
│   ├── gameboard/  # Map and pathfinding
│   ├── gamepieces/ # Base entity system
│   ├── items/      # Item implementations
│   └── npcs/       # NPC implementations
└── ui/             # User interface
```

### Core Systems

1. Field System (`src/field/field.gd`)
   - Manages the game world
   - Handles tile-based movement
   - Controls cursor interaction
   - Manages entities (NPCs and items)

2. Gameboard System (`src/field/gameboard/`)
   - Pathfinding (`pathfinder.gd`)
   - Map boundaries (`debug_map_boundaries.gd`)
   - Collision detection

3. Gamepiece System (`src/field/gamepieces/`)
   - Base class for all entities
   - Animation system
   - Controller system

## Implementation Guide

### 1. Placeholder Item Implementation

Create the following item hierarchy in `src/field/items/`:

```
items/
├── bedroom/
│   └── bed.tscn
├── bathroom/
│   ├── shower.tscn
│   └── toilet.tscn
└── kitchen/
    ├── fridge.tscn
    ├── oven.tscn
    ├── trash_can.tscn
    └── food_item.tscn
```

Each item scene should:
- Inherit from gamepiece.tscn
- Use static sprites
- Include collision shapes
- Add item-specific controllers

### 2. Item Interaction Components

Create base interaction components in `src/field/items/components/`:

```
components/
├── sleepable.gd        # For bed
├── hygiene.gd          # For shower
├── bladder.gd          # For toilet
├── storage.gd          # For fridge/freezer
├── cooking.gd          # For oven
├── disposable.gd       # For trash can
└── consumable.gd       # For food items
```

Example implementations:

```gdscript
# src/field/items/bedroom/bed_controller.gd
extends "res://src/field/items/item_controller.gd"

func _ready():
    super._ready()
    # Add sleepable component
    var sleep_component = preload("res://src/field/items/components/sleepable.gd").new()
    add_child(sleep_component)

# src/field/items/components/sleepable.gd
extends Node

const SLEEP_DURATION = 8 * 60 * 60  # 8 hours in seconds

func start_sleep(npc):
    # Emit sleep started event
    FieldEvents.emit_signal("sleep_started", {
        "npc": npc,
        "duration": SLEEP_DURATION
    })

# src/field/interactions/interaction.gd
# Add interaction types
enum InteractionType {
    SLEEP,
    HYGIENE,
    BLADDER,
    STORE,
    COOK,
    DISPOSE,
    CONSUME
}

# src/field/npcs/npc_controller.gd
# Add interaction handling
func handle_interaction(interaction: Dictionary):
    match interaction.type:
        InteractionType.SLEEP:
            # Handle sleep state
            current_state = NPCState.SLEEPING
            dream_end_time = Time.get_unix_time_from_system() + interaction.duration
```

Implementation Pattern:
1. Scene setup inheriting from gamepiece.tscn
2. Controller extension with specific behavior
3. Component addition for interaction type
4. Integration with event system
5. NPC controller updates for handling the interaction

### 3. Event System Usage

The event system facilitates communication:

```gdscript
# Example event usage
FieldEvents.emit_signal("interaction_started", {
    "source": self,
    "target": item
})
```

### 4. Component System

Components extend entity functionality:

```gdscript
# Example component
extends Node

func _ready() -> void:
    # Initialize component
```

## Best Practices

1. Use the Component Pattern
   - Extend functionality through components
   - Keep components focused and reusable
   - Follow established patterns

2. Event-Driven Communication
   - Use FieldEvents for inter-entity communication
   - Maintain loose coupling
   - Handle cleanup properly

3. Controller Implementation
   - Extend from appropriate base controllers
   - Implement required virtual methods
   - Use the state pattern for complex behaviors

4. Resource Management
   - Use Godot's resource system
   - Implement proper cleanup
   - Follow singleton patterns where appropriate

## Common Patterns

1. Entity Creation
```gdscript
# Creating a new entity
var entity = preload("res://src/field/gamepieces/gamepiece.tscn").instantiate()
add_child(entity)
```

2. Component Addition
```gdscript
# Adding a component
var component = Node.new()
entity.add_child(component)
```

3. Event Handling
```gdscript
# Connecting to events
FieldEvents.connect("interaction_completed", _on_interaction_completed)
```

## Debugging Tools

1. Debug Overlay
   - Entity states
   - Pathfinding visualization
   - Component status

2. Event Monitoring
   - Track event emissions
   - Monitor state changes
   - Debug interaction flow
