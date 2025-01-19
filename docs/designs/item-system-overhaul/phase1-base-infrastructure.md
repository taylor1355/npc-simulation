# Phase 1: Base Infrastructure

## Objective
Create the foundational structure for the new item system while maintaining compatibility with existing items.

## Components

### 1. Base Item Scene (base_item.tscn)
```
BaseItem (extends gamepiece.tscn)
├── Decoupler
├── Animation
│   ├── AnimationPlayer
│   ├── GFX
│   │   ├── Sprite
│   │   ├── Shadow
│   │   └── ClickArea
│   └── CollisionArea
└── ItemController
```

#### Implementation
```gdscript
# base_item.gd
class_name BaseItem
extends Gamepiece

@onready var sprite: Sprite2D = $Animation/GFX/Sprite
@onready var collision_shape: CollisionShape2D = $Animation/CollisionArea/CollisionShape2D
@onready var item_controller: ItemController = $ItemController

func _ready() -> void:
    super._ready()
    # Verify required nodes exist
    assert(sprite != null, "Sprite node missing")
    assert(collision_shape != null, "CollisionShape node missing")
    assert(item_controller != null, "ItemController node missing")
```

#### Testing Steps
1. Scene Structure
   - Create scene in editor
   - Set breakpoint in _ready()
   - Verify node paths resolve
   - Check inheritance chain

2. Runtime Verification
   ```gdscript
   # Add temporary debug
   print("Sprite path: ", sprite.get_path())
   print("Collision path: ", collision_shape.get_path())
   print("Controller path: ", item_controller.get_path())
   ```

### 2. Component Configuration

#### Implementation
```gdscript
# component_config.gd
@tool
class_name ItemComponentConfig
extends Resource

@export var component_script: Script
@export var properties: Dictionary

func _init():
    component_script = null
    properties = {}

func _validate_properties() -> bool:
    if not component_script:
        push_error("Component script not set")
        return false
        
    # Create temporary instance to validate properties
    var temp = component_script.new()
    for key in properties:
        if not key in temp:
            push_error("Invalid property '%s'" % key)
            return false
    temp.free()
    return true
```

#### Testing Steps
1. Resource Creation
   ```gdscript
   # Create test config
   var config = ItemComponentConfig.new()
   config.component_script = preload("res://path/to/test_component.gd")
   config.properties = {"test_value": 42}
   
   # Set breakpoint after creation
   # Verify in debugger:
   # - Script loaded
   # - Properties set
   ```

2. Validation Testing
   ```gdscript
   # Test invalid properties
   config.properties = {"invalid_key": 123}
   assert(not config._validate_properties())
   
   # Test missing script
   config.component_script = null
   assert(not config._validate_properties())
   ```

### 3. Item Factory

#### Implementation
```gdscript
# item_factory.gd
class_name ItemFactory

const BASE_ITEM_SCENE = preload("res://src/field/items/base_item.tscn")

static func create_item(config: Dictionary, item_name: String = "") -> Node:
    var item = BASE_ITEM_SCENE.instantiate()
    
    if config.has("sprite_config"):
        _configure_sprite(item, config.sprite_config)
    
    if config.has("collision_shape"):
        _configure_collision(item, config.collision_shape)
        
    if config.has("components"):
        for component_config in config.components:
            item.get_node("ItemController").add_component(component_config)
    
    if item_name:
        item.name = item_name
        
    return item
```

#### Testing Steps
1. Basic Creation
   ```gdscript
   # Create minimal item
   var item = ItemFactory.create_item({})
   # Set breakpoint
   # Verify structure
   ```

2. Full Configuration
   ```gdscript
   # Test all options
   var item = ItemFactory.create_item({
       "sprite_config": {
           "texture": preload("res://assets/sprites/test.png"),
           "hframes": 4
       },
       "collision_shape": CircleShape2D.new(),
       "components": [test_config]
   }, "TestItem")
   
   # Verify in debugger:
   # - Sprite configured
   # - Collision shape set
   # - Components added
   # - Name applied
   ```

## Integration Testing

### Test Scene Setup
1. Create test scene
2. Add factory-created items
3. Test interactions
4. Verify component behavior

### Error Cases
1. Missing nodes in base scene
2. Invalid component configurations
3. Resource loading failures

### Performance Testing
1. Create multiple items
2. Monitor memory usage
3. Check instantiation time

## Success Criteria

### Technical
- [ ] Base scene loads correctly
- [ ] Component config validates properties
- [ ] Factory creates complete items

### Functional
- [ ] Items appear correctly
- [ ] Collision works
- [ ] Components function

## Next Steps

1. Documentation
   - Update creating-new-item-tutorial.md
   - Add code comments
   - Document testing procedures

2. Cleanup
   - Remove debug code
   - Organize resource files
   - Update existing items

3. Phase 2 Preparation
   - Plan component system
   - Identify migration needs
   - Draft conversion strategy
