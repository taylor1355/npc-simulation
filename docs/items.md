# Item System

## Core Components

### Controller (item_controller.gd)
```
Key Features:
├── Component Management
│   ├── add_component(config: ItemComponentConfig)
│   ├── add_component_node(component: GamepieceComponent)
│   └── Automatic interaction registration
├── Interaction System
│   ├── interactions: Dictionary of available actions
│   ├── current_interaction: Active interaction
│   ├── interacting_npc: Current NPC reference
│   └── interaction_time: Duration tracking
└── Event Handling
    └── interaction_finished signal
```

### Component System
```
Base Component:
├── Properties
│   ├── interactions: Dictionary
│   └── interaction_finished signal
└── Integration
    ├── Automatic controller discovery
    └── Event forwarding

ConsumableComponent Example:
├── Configuration
│   ├── need_deltas: Dictionary (need changes)
│   └── consumption_time: float (duration)
├── State
│   ├── percent_left: float (0-100)
│   └── current_npc: NpcController
├── Features
│   ├── Creates NeedModifyingComponent
│   ├── Configures need rates
│   └── Auto-cleanup at 0% percent_left
└── Interaction Flow
    ├── Start: Validates and begins consumption
    ├── Process: Updates percent_left
    ├── Cancel: Handles early termination
    └── Finish: Cleanup and destruction
```

### Component Configuration (`src/field/items/components/component_config.gd`)
`ItemComponentConfig` is a `Resource` type designed to define the setup for a specific component that can be attached to an item. These configurations are typically created and saved as `.tres` files using the Godot editor.

**Key Properties (exported for editor):**

*   **`component_script: Script`**: A reference to the script file of the component that this configuration will instantiate (e.g., `ConsumableComponent.gd`). This is a required field.
*   **`properties: Dictionary`**: A dictionary where keys are property names (strings) and values are the desired initial values for those properties on the component instance.
    *   Example: `{"consumption_time": 5.0, "need_deltas": {"hunger": 50.0}}` would set the `consumption_time` to `5.0` and `need_deltas` to the given dictionary on the component instance, assuming the component script has these properties.

**Practical Usage:**

1.  **Create Config Resource:** In the Godot FileSystem dock, right-click, choose "New Resource...", search for `ItemComponentConfig`, and save it (e.g., as `my_consumable_config.tres`).
2.  **Assign Script:** Select the created `.tres` file. In the Inspector, drag your component script (e.g., `ConsumableComponent.gd` from the FileSystem dock) to the `Component Script` property.
3.  **Define Properties:** In the `Properties` dictionary field in the Inspector, add entries for each property you want to initialize on the component. The keys must match the property names in your component script.
4.  **Use in `ItemConfig`:** This `ItemComponentConfig` resource is then typically added to an array of component configurations within an `ItemConfig` resource (which defines the complete item). When the item is instantiated, its `ItemController` will iterate through these configurations to add and set up each component. It can also be used when adding components dynamically via `item_controller.add_component(config: ItemComponentConfig)`.

**Validation:**
The `ItemComponentConfig` resource has a basic internal validation (`_validate()` method) that primarily ensures the `component_script` property has been assigned. Further validation (e.g., whether the properties in the `properties` dictionary correctly match and are assignable to the actual properties of the `component_script`) is implicitly handled by Godot when it attempts to set these properties on the instantiated component. Errors might occur at runtime if property names or types mismatch.
```

## Integration

### Component Setup
```gdscript
# Create and configure component
var component = ConsumableComponent.new()
component.need_deltas = {
    "hunger": hunger_need_delta,  # Configure rates at which
    "energy": energy_need_delta   # consumption affects needs
}
component.consumption_time = duration  # Set consumption duration

# Add to controller
item_controller.add_component_node(component)
```

### Interaction Flow
```
Request Phase:
1. NPC sends InteractionRequest
2. Controller validates:
   - No current interaction
   - Interaction exists
   - Valid request type
3. Component handles request:
   - Validates preconditions
   - Sets up state
   - Configures related components

Execution:
1. Controller tracks time
2. Component updates state
3. Monitors completion
4. Handles cancellation
5. Cleanup on finish
```

### Event System
```
Interaction Events:
├── Start Request
│   ├── Validation
│   └── State setup
├── Cancel Request
│   ├── State verification
│   └── Cleanup
└── Finished
    ├── State reset
    ├── Resource cleanup
    └── Event dispatch
```
