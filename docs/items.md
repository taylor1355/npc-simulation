# Item System

## Overview

The item system implements interactive objects that NPCs can discover and use to satisfy their needs. The system follows a component-based architecture where items gain functionality through modular components, allowing flexible combinations of behaviors without inheritance hierarchies.

The architecture separates concerns into three layers:
- **Controller**: Manages the item's lifecycle and coordinates components
- **Components**: Implement specific behaviors (consuming, sitting, etc.)
- **Configuration**: Data-driven setup through Godot resources

This design enables designers to create new items entirely through the editor by combining existing components with different configurations, without writing code.

Core concepts:
- Items are static objects placed in the world that NPCs can interact with
- Each item can have multiple components that define its behaviors
- Components use a declarative property system for type-safe configuration
- Interactions follow a request-response pattern with explicit state management

## Core Architecture

### Controller (item_controller.gd)

The ItemController serves as the central coordinator for an item's functionality. It manages the lifecycle of components, tracks active interactions, and ensures proper cleanup when interactions complete or are cancelled.

```
Key Responsibilities:
├── Component Management
│   ├── add_component(config: ItemComponentConfig) - Adds components from configuration
│   ├── add_component_node(component: GamepieceComponent) - Registers runtime components
│   └── Automatic property configuration via component.configure_properties()
├── Interaction Coordination
│   ├── interactions: Dictionary[String, Interaction] - Merged from all components
│   ├── current_interaction: Interaction - Enforces single active interaction
│   ├── interacting_npc: NpcController - Tracks who is using the item
│   └── interaction_time: float - Measures interaction duration
└── State Management
    ├── request_interaction() - Validates and routes interaction requests
    └── interaction_finished signal - Notifies when interactions complete
```

The controller enforces important constraints:
- Only one NPC can interact with an item at a time
- Interactions must be explicitly started and finished
- Failed interactions trigger appropriate error events

### Component System (item_component.gd)

The component system introduces a powerful property specification pattern that eliminates the boilerplate traditionally required for type conversion and validation. This approach dramatically reduces the code needed to create new components while maintaining type safety.

**Property Specification Pattern**

Instead of manually parsing configuration dictionaries and converting types, components declare their properties using PropertySpec objects:

```gdscript
# Traditional approach (before refactoring):
@export var consumption_time: float = 1.0
@export var need_deltas_config: Dictionary = {}

func _ready():
    # Manual type conversion for each property
    if need_deltas_config.has("hunger"):
        var hunger_value = need_deltas_config["hunger"]
        if hunger_value is float:
            need_deltas[Needs.Need.HUNGER] = hunger_value
    # ... repeat for each need type

# New PropertySpec approach:
func _init():
    PROPERTY_SPECS["consumption_time"] = PropertySpec.new(
        "consumption_time", 
        TypeConverters.PropertyType.FLOAT, 
        1.0
    )
    PROPERTY_SPECS["need_deltas"] = PropertySpec.new(
        "need_deltas", 
        TypeConverters.PropertyType.NEED_DICT, 
        {}
    )

var consumption_time: float = 1.0
var need_deltas: Dictionary[Needs.Need, float] = {}
```

The base ItemComponent class automatically:
1. Reads property values from configuration
2. Converts them to the correct types using TypeConverters
3. Sets the converted values on the component
4. Handles errors with helpful messages showing available properties

**Component Structure**

```
ItemComponent (Base Class)
├── Property System
│   ├── PROPERTY_SPECS: Dictionary[String, PropertySpec] - Declarative property definitions
│   ├── configure_properties(properties: Dictionary) - Called by controller with config values
│   ├── _auto_process_properties() - Processes properties defined via _set()
│   └── PropertySpec class
│       ├── name: String - Property identifier
│       ├── property_type: TypeConverters.PropertyType - Expected type
│       ├── default_value: Variant - Used when not configured
│       └── description: String - Documentation
├── Interaction Management
│   ├── interactions: Dictionary[String, Interaction] - Component's available actions
│   ├── interaction_finished signal - Emitted when interaction completes
│   └── Interaction lifecycle hooks for request handling
└── Lifecycle Methods
    ├── _init() - Define PROPERTY_SPECS here
    ├── _component_ready() - Called after properties are configured
    └── Standard Godot lifecycle (_ready, _process, etc.)
```

### Type Conversion System (type_converters.gd)

The type conversion system centralizes the complex logic of converting between Godot's variant types and the specific types components expect. This is particularly important for dictionary conversions where keys need to be transformed from strings or integers to enums.

```
TypeConverters
├── PropertyType enum - Supported conversion types
│   ├── FLOAT - Basic numeric values
│   ├── STRING - Text values
│   ├── BOOL - Boolean flags
│   ├── INT - Integer values
│   ├── VECTOR2 - 2D positions
│   ├── NEED_DICT - Dictionary[Needs.Need, float] (special handling)
│   └── (extensible for new types)
└── convert(value: Variant, type: PropertyType, default: Variant) -> Variant
    ├── Handles null/invalid inputs gracefully
    ├── Performs type-specific conversions
    └── Returns default value on conversion failure
```

The NEED_DICT type showcases the system's power - it converts dictionaries with string or integer keys into properly typed Dictionary[Needs.Need, float] that components can use directly.

## Component Implementation

### Creating a New Component

When creating a component, you define its configurable properties in `_init()` and use them in `_component_ready()`:

```gdscript
class_name CustomItemComponent extends ItemComponent

func _init():
    # Define all configurable properties with their types and defaults
    PROPERTY_SPECS["activation_time"] = PropertySpec.new(
        "activation_time",                     # Property name
        TypeConverters.PropertyType.FLOAT,     # Expected type
        2.0,                                   # Default value
        "Time to activate this item"           # Description for documentation
    )
    
    PROPERTY_SPECS["effect_strength"] = PropertySpec.new(
        "effect_strength", 
        TypeConverters.PropertyType.FLOAT, 
        10.0,
        "Strength of the item's effect"
    )

# Declare typed properties that match PROPERTY_SPECS
var activation_time: float = 2.0
var effect_strength: float = 10.0

func _component_ready() -> void:
    # At this point, properties have been configured from ItemConfig
    # Set up interactions using the configured values
    
    var interaction = Interaction.new(
        "activate",
        "Activate item (%.1fs)" % activation_time,
        [],  # Filled needs
        []   # Drained needs
    )
    
    interactions[interaction.name] = interaction
    interaction.start_request.connect(_on_activate_start)
    interaction.cancel_request.connect(_on_activate_cancel)

func _on_activate_start(request: InteractionRequest) -> void:
    # Validate the request
    if not _can_activate():
        request.reject("Cannot activate right now")
        return
    
    request.accept()
    # Begin activation process...
```

### Built-in Components

#### ConsumableComponent

Handles items that NPCs consume over time to satisfy needs (food, drinks, medicine).

**Key Features:**
- Progressive consumption tracked by `percent_left` (100% → 0%)
- Automatic item destruction when fully consumed
- NPC rotation to face the item being consumed
- Integration with NeedModifyingComponent for gradual need satisfaction

**Properties:**
- `consumption_time: float` - Total time to consume the item
- `need_deltas: Dictionary[Needs.Need, float]` - Total need changes when fully consumed

**Implementation Details:**
The component creates a child NeedModifyingComponent and calculates rates by dividing the total need changes by consumption time. This ensures smooth, gradual satisfaction of needs rather than instant changes.

#### NeedModifyingComponent

Provides continuous modification of NPC needs over time. Used both standalone and as a child of other components.

**Key Features:**
- Accumulates fractional changes to avoid precision loss
- Applies changes only when they exceed the update threshold
- Supports both positive (satisfaction) and negative (drain) rates
- Provides human-readable effect descriptions

**Properties:**
- `need_rates: Dictionary[Needs.Need, float]` - Per-second change rates
- `update_threshold: float` - Minimum accumulated change before applying (default: 1.0)

**Use Cases:**
- Chairs that restore energy while sitting
- Workstations that drain energy but increase fun
- Environmental effects that impact multiple needs

#### SittableComponent

Manages furniture that NPCs can sit on, handling the complex state transitions required for proper positioning.

**Key Features:**
- Movement locking while seated
- Proper z-index management when NPC and chair share the same cell
- Smart exit positioning to find unblocked adjacent cells
- Configurable need restoration while sitting

**Properties:**
- `energy_regeneration_rate: float` - Energy restored per second (default: 10.0)

**Implementation Details:**
The sitting process involves several careful steps:
1. Verify NPC is adjacent to chair
2. Lock NPC movement
3. Temporarily disable chair collision
4. Move NPC to chair position with proper z-index
5. Re-enable chair collision
6. Begin need modification

The exit process reverses this, finding a safe adjacent cell for the NPC.

## Configuration System

### Resource-Based Configuration

The item system uses Godot's resource system for configuration, enabling visual editing and version control benefits:

#### ItemConfig Resource (item_config.gd)
The main configuration for an item, containing display information and component setup.

```
ItemConfig extends Resource
├── display_name: String - Human-readable name
├── scene: PackedScene - Visual representation (must have Gamepiece root)
└── components: Array[ItemComponentConfig] - Components to add
```

#### ItemComponentConfig Resource (component_config.gd)
Defines a single component to be added to an item.

```
ItemComponentConfig extends Resource
├── component_script: Script - The component class (e.g., ConsumableComponent)
└── properties: Dictionary - Property values to configure
    └── Keys must match PROPERTY_SPECS in the component
```

### Creating Items in the Editor

The typical workflow for creating a new item:

1. **Create the ItemConfig Resource**
   - Right-click in FileSystem dock
   - Choose "New Resource" → Search "ItemConfig"
   - Save as `res://items/configs/my_item_config.tres`

2. **Set Basic Properties**
   - Display Name: "My Item"
   - Scene: Drag your item's `.tscn` file

3. **Add Components**
   - In the components array, click "Add Element"
   - Choose "New ItemComponentConfig"
   - Set the component script (drag from FileSystem)
   - Configure properties in the dictionary

4. **Configure Properties**
   Example for an apple:
   ```
   Component Script: ConsumableComponent
   Properties: {
       "consumption_time": 3.0,
       "need_deltas": {
           0: 25.0  # Note: Use integer keys for enums in editor
       }
   }
   ```

### Property Configuration Notes

When configuring in the editor:
- Numeric enum values must be used as dictionary keys (0 for HUNGER, etc.)
- The type conversion system handles the conversion to proper enum types
- Invalid properties show warnings with available property names
- Default values are used for unconfigured properties

## Best Practices

### Component Design
1. Keep components focused on a single responsibility
2. Use composition over inheritance - combine simple components for complex behaviors
3. Always validate interaction requests before accepting
4. Clean up state properly when interactions end
5. Emit clear rejection reasons to help with debugging

### Property Configuration
1. Choose appropriate types from TypeConverters.PropertyType
2. Provide sensible default values
3. Write clear descriptions for each property
4. Consider which properties should be configurable vs. internal state

### Error Handling
1. The system provides detailed warnings for configuration errors
2. Check the console for property mismatch warnings
3. Use the enhanced error messages that show available properties
4. Test component configurations in isolation

## Key Files Reference

- `src/field/items/item_controller.gd` - Main controller logic
- `src/field/items/components/item_component.gd` - Base component class with PropertySpec
- `src/field/items/components/type_converters.gd` - Type conversion system
- `src/field/items/item_config.gd` - Main item configuration resource
- `src/field/items/components/component_config.gd` - Component configuration resource
- `src/field/items/item_factory.gd` - Handles item instantiation from configs
- `src/field/items/items_manager.gd` - Manages all items in the scene
