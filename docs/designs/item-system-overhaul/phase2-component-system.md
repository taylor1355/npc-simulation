# Phase 2: Component System

## Objective
Implement a robust component system that integrates with GamepieceController while providing item-specific functionality.

## Components

### 1. Item Component Base Class

#### Implementation
```gdscript
# item_component.gd
class_name ItemComponent
extends GamepieceComponent

var item_controller: ItemController

func _ready() -> void:
    super._ready()
    if not Engine.is_editor_hint():
        item_controller = controller as ItemController
        if not item_controller:
            push_error("ItemComponent must be child of an ItemController")

func get_component_name() -> String:
    # Override parent method for cleaner names
    var script_path = get_script().resource_path
    var file_name = script_path.get_file().get_basename()
    return file_name.replace("_component", "").capitalize()
```

#### Testing Steps
1. Component Registration
   ```gdscript
   # Create test component
   class TestComponent extends ItemComponent:
       var test_value: int
       
       func _setup() -> void:
           # Set breakpoint here
           print("Setup called with controller: ", item_controller)
           
   # Add to scene
   # Verify in debugger:
   # - _ready called
   # - controller reference set
   # - _setup called
   ```

2. Name Generation
   ```gdscript
   # Test various component names
   var test_comp = TestComponent.new()
   print(test_comp.get_component_name())  # Should print "Test"
   
   var need_mod_comp = NeedModifyingComponent.new()
   print(need_mod_comp.get_component_name())  # Should print "NeedModifying"
   ```

### 2. Component Property System

#### Implementation
```gdscript
# item_controller.gd
class_name ItemController
extends GamepieceController

func add_component(component_config: ItemComponentConfig) -> void:
    # Create component instance
    var component = component_config.component_script.new()
    
    # Configure properties
    for key in component_config.properties:
        if not key in component:
            push_error("Invalid property '%s' for component %s" % [key, component.get_component_name()])
            continue
        component.set(key, component_config.properties[key])
    
    # Add to scene tree - GamepieceComponent._ready() handles registration
    add_child(component)
    
    # Verify registration
    assert(component in components, "Component failed to register")

func get_typed_component(type: GDScript) -> ItemComponent:
    var component = get_component(type)
    return component as ItemComponent if component else null
```

#### Testing Steps
1. Property Application
   ```gdscript
   # Create test component
   class TestComponent extends ItemComponent:
       var string_value: String
       var int_value: int
       var dict_value: Dictionary
   
   # Create config
   var config = ItemComponentConfig.new()
   config.component_script = TestComponent
   config.properties = {
       "string_value": "test",
       "int_value": 42,
       "dict_value": {"key": "value"}
   }
   
   # Set breakpoint in add_component
   # Verify each property set correctly
   ```

2. Error Handling
   ```gdscript
   # Test invalid property
   config.properties["invalid_key"] = "value"
   # Verify error message
   
   # Test invalid type
   config.properties["int_value"] = "not an int"
   # Verify type error
   ```

### 3. Component Interactions

#### Implementation
```gdscript
# consumable_component.gd
class_name ConsumableComponent
extends ItemComponent

@export var consumption_time: float = 5.0
@export var need_deltas: Dictionary = {}

func _setup() -> void:
    # Register for interaction events
    item_controller.interaction_started.connect(_on_interaction_started)
    item_controller.interaction_completed.connect(_on_interaction_completed)

func _on_interaction_started(interactor: Node) -> void:
    if interactor.has_method("modify_needs"):
        # Start consumption animation
        item_controller.get_node("Animation/AnimationPlayer").play("consume")

func _on_interaction_completed(interactor: Node) -> void:
    if interactor.has_method("modify_needs"):
        # Apply need changes
        interactor.modify_needs(need_deltas)
        # Queue item for deletion
        item_controller.get_parent().queue_free()
```

#### Testing Steps
1. Event Connections
   ```gdscript
   # Set breakpoint in _setup
   # Verify signal connections
   ```

2. Interaction Flow
   ```gdscript
   # Create test scene
   var item = create_test_item()
   var interactor = create_test_interactor()
   
   # Test interaction
   # Breakpoints at:
   # 1. interaction_started
   # 2. animation start
   # 3. interaction_completed
   # 4. need modification
   # 5. cleanup
   ```

## Integration Testing

### Test Scene Setup
1. Create test scene with:
   - Multiple items
   - Different component combinations
   - Test interactor

### Component Combinations
1. Single Component
   ```gdscript
   var item = ItemFactory.create_item({
       "components": [consumable_config]
   })
   ```

2. Multiple Components
   ```gdscript
   var item = ItemFactory.create_item({
       "components": [
           consumable_config,
           need_modifying_config
       ]
   })
   ```

### Error Cases
1. Component Conflicts
   - Components with conflicting properties
   - Multiple instances of same component

2. Property Validation
   - Missing required properties
   - Invalid property types
   - Runtime property changes

### Performance Testing
1. Component Loading
   - Time to instantiate
   - Memory usage
   - Cleanup verification

## Success Criteria

### Technical
- [ ] Components auto-register
- [ ] Properties correctly applied
- [ ] Type safety maintained
- [ ] Clean error handling

### Functional
- [ ] Components interact properly
- [ ] Events work correctly
- [ ] State maintained
- [ ] Memory managed

## Next Steps

1. Documentation
   - Update component docs
   - Add property type hints
   - Document common patterns

2. Cleanup
   - Remove debug code
   - Optimize property system
   - Standardize error messages

3. Phase 3 Preparation
   - Plan event system
   - Identify component events
   - Draft validation improvements
