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

When an `ItemComponent` is configured (typically by `ItemController` calling the component's `configure_properties` method with values from an `ItemComponentConfig`):
1.  For each property defined in the component's `PROPERTY_SPECS` dictionary:
    *   The raw value from the configuration is retrieved.
    *   This raw value is converted to the `property_type` specified in its `PropertySpec` (e.g., `TypeConverters.PropertyType.FLOAT`), using `TypeConverters`. This step also applies the `default_value` from the `PropertySpec` if the raw value is missing or conversion fails.
    *   The successfully converted, type-safe value is then assigned directly to the corresponding member variable of the component instance (e.g., if `PROPERTY_SPECS` defines "consumption_time", the `var consumption_time: float` member variable in the component script is set).
2.  Error Handling: If a property name from the configuration doesn't exist in `PROPERTY_SPECS`, or if a value cannot be converted, warnings are issued.
Components can then access these configured member variables directly in their logic, typically starting from the `_component_ready()` method.

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

### Type Conversion System (`src/field/items/components/type_converters.gd`)

The `TypeConverters` class (extends `RefCounted`) centralizes the logic for converting property values (often from string-based or generic `Variant` types in configuration files or editor properties) into the specific, strongly-typed data that `ItemComponent`s expect. This is crucial for robustly handling `Dictionary` properties where keys might need to be converted to enums or specific string formats.

**Key Features:**
*   **`PropertyType` Enum:** Defines the set of target types the system can convert to. As of the last review, these include:
    *   `FLOAT`: For floating-point numbers.
    *   `INT`: For integer numbers.
    *   `STRING`: For text strings.
    *   `BOOL`: For boolean true/false values.
    *   `NEED_DICT`: Specialised for `Dictionary[Needs.Need, float]`, converting string or integer keys to `Needs.Need` enums.
    *   `TYPED_FLOAT_DICT`: For `Dictionary[String, float]`, ensuring keys are strings and values are floats.
    *   `VARIANT`: A pass-through for when no specific conversion is needed, or the type is inherently `Variant`.
*   **`convert(value: Variant, property_type: PropertyType, default_value: Variant = null) -> Variant`:** The main static method used for conversion.
    *   Takes the input `value`, the target `property_type`, and an optional `default_value`.
    *   Uses an internal registry of converter functions (`Callable`s) for each `PropertyType`.
    *   Handles `null` inputs gracefully by returning the `default_value`.
    *   If conversion fails or the type is unknown, it issues a warning and returns the `default_value`.
*   **Extensibility:** While it includes built-in converters for common types, it also has a `register_converter(property_type: PropertyType, converter: Callable)` method to allow for new custom types and their conversion logic to be added.
*   **Specialized Dictionary Conversion:** The `_convert_to_need_dict` method is a good example of its capability to handle complex dictionary transformations, ensuring that dictionaries representing need modifications are correctly typed for use by components (e.g., converting `{"0": 25.0}` or `{"hunger": 25.0}` to `{Needs.Need.HUNGER: 25.0}`).

This system is integral to the `ItemComponent`'s property specification pattern, enabling components to declare their required data types and have the `TypeConverters` handle the actual conversion from raw configuration data.

## Component Implementation

### Creating a New Component

When creating a component, you define its configurable properties in `_init()` using `PropertySpec` (which specifies the `TypeConverters.PropertyType`) and then use the automatically converted, typed properties in methods like `_component_ready()`:

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

#### ItemConfig Resource (`src/field/items/item_config.gd`)
The `ItemConfig` resource defines the properties for a specific type of item, including its appearance, collision, and attached components.

```
ItemConfig extends Resource
    @export var item_name: String         # Unique name for the item type (e.g., "Apple", "Wooden Chair").
    @export var sprite_texture: Texture2D # The texture for the item's sprite.
    @export var sprite_hframes: int = 1   # Number of horizontal frames in the sprite_texture.
    @export var sprite_vframes: int = 1   # Number of vertical frames in the sprite_texture.
    @export var sprite_frame: int = 0     # The specific frame to display from the spritesheet.
    @export var collision_shape: Shape2D  # The collision shape for the item.
    @export var components: Array[ItemComponentConfig] # An array of configurations for components to be added to this item.
```
The resource includes a `_validate()` method that checks if `item_name`, `sprite_texture`, and `collision_shape` are set, and also validates all its `ItemComponentConfig`s. This configuration is used by `ItemFactory` to create item instances and by `BaseItem` to initialize itself.

#### ItemComponentConfig Resource (`src/field/items/components/component_config.gd`)
Defines a single component to be added to an item.

```
ItemComponentConfig extends Resource
├── component_script: Script - The component class (e.g., ConsumableComponent)
└── properties: Dictionary - Property values to configure
    └── Keys must match PROPERTY_SPECS in the component
```

### Creating Items in the Editor

The typical workflow for creating a new item using the resource-based configuration:

1.  **Create the `ItemConfig` Resource:**
    *   In the FileSystem dock, right-click the desired folder (e.g., `res://items/configs/`).
    *   Choose "New Resource..."
    *   Search for and select `ItemConfig`.
    *   Save the new resource (e.g., `my_new_item_config.tres`).

2.  **Configure `ItemConfig` Properties (in the Inspector):**
    *   **`Item Name`**: Set a unique identifier for this item type (e.g., "MagicPotion", "OfficeDesk"). This name is used by `BaseItem` to set its node name and `display_name`.
    *   **`Sprite Texture`**: Assign the `Texture2D` resource for the item's visual representation.
    *   **`Sprite Hframes` / `Sprite Vframes` / `Sprite Frame`**: Configure these if your `sprite_texture` is a spritesheet to select the correct frame. Defaults are 1, 1, and 0 respectively.
    *   **`Collision Shape`**: Assign a `Shape2D` resource (e.g., `RectangleShape2D`, `CircleShape2D`) that defines the item's physical boundaries for collision detection.
    *   (The actual item scene, `res://src/field/items/base_item.tscn`, is used by `ItemFactory` as a template. The `BaseItem` script then applies these `ItemConfig` properties to its internal `Sprite2D` and `CollisionShape2D` nodes.)

3.  **Add Components (in the `ItemConfig`'s `Components` array):**
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

### Item Factory (`src/field/items/item_factory.gd`)
The `ItemFactory` is a static utility class responsible for creating `BaseItem` instances from `ItemConfig` resources.
*   **`create_item(config: ItemConfig, gameboard: Gameboard, position: Vector2i = Vector2i.ZERO) -> BaseItem`**: This is the primary static method. It:
    1.  Validates the provided `ItemConfig`.
    2.  Instantiates the `BASE_ITEM_SCENE` (which is `res://src/field/items/base_item.tscn`).
    3.  Assigns the `gameboard` reference and initial `position` (in cell coordinates, which `BaseItem` will convert to pixels) to the new item instance.
    4.  Sets the `config` property on the `BaseItem`. The `BaseItem` then handles its own full initialization (sprite, collision, components) in its `_ready` or `_initialize_item` method using this config.
*   **Specific Factory Methods:** It also includes helper methods like `create_apple(gameboard, position)` and `create_chair(gameboard, position)` that preload specific `ItemConfig` resources (e.g., `apple_config.tres`) and then call `create_item`.

This factory simplifies the process of spawning new items in the game world.

### Items Manager (`src/field/items/items_manager.gd`)
The `ItemsManager` (extends `Node2D`) is responsible for managing all active item instances within a game scene.
*   **Scene Organization:** It typically acts as a parent node for all spawned items, with `y_sort_enabled = true` to ensure correct 2D draw order based on Y position.
*   **Item Spawning:**
    *   `spawn_item(item: BaseItem)`: Adds a pre-created `BaseItem` instance as a child to the manager, bringing it into the active scene.
    *   Provides helper methods like `spawn_apple()` and `spawn_chair()` which:
        1.  Determine a random position on the linked `gameboard` using its `get_random_position()` utility method.
        2.  Use `ItemFactory` to create the specific item instance with the chosen configuration and position.
        3.  Call its own `spawn_item()` method to add the new item to the scene.
*   **Gameboard Reference:** Requires a `gameboard: Gameboard` reference to determine valid spawning positions.

This node centralizes runtime item management and facilitates dynamic item placement.

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
