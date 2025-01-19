# Phase 4: Item Migration

## Objective
Convert existing items to use the new system while maintaining functionality and ensuring backward compatibility during migration.

## Current Items

### Apple
Current Implementation:
- Separate scene (apple.tscn)
- Hardcoded properties
- Direct event emission

### Chair
Current Implementation:
- Separate scene (chair.tscn)
- Custom animation setup
- Direct need modification

## Migration Steps

### 1. Component Configurations

#### Apple Configuration
```gdscript
# configs/consumable_apple_config.tres
@tool
extends ItemComponentConfig

@export var component_script = preload("res://src/field/items/components/consumable_component.gd")
@export var properties = {
    "consumption_time": 5.0,
    "need_deltas": {
        "hunger": 25.0
    }
}
```

#### Testing Steps
1. Resource Creation
   ```gdscript
   # Load config
   var config = preload("res://src/field/items/configs/consumable_apple_config.tres")
   
   # Set breakpoint after load
   # Verify:
   # - Script reference
   # - Property values
   ```

### 2. Factory Methods

#### Implementation
```gdscript
# item_factory.gd
class_name ItemFactory

static func create_apple() -> Node:
    var config = preload("res://src/field/items/configs/consumable_apple_config.tres")
    return create_item({
        "sprite_config": {
            "texture": preload("res://assets/sprites/apple_spritesheet.png"),
            "hframes": 8,
            "frame": 0
        },
        "collision_shape": (func(): 
            var s = CircleShape2D.new()
            s.radius = 6.5
            return s
        ).call(),
        "components": [config]
    }, "Apple")

static func create_chair() -> Node:
    var config = preload("res://src/field/items/configs/sittable_chair_config.tres")
    return create_item({
        "sprite_config": {
            "texture": preload("res://assets/sprites/chairs.webp"),
            "hframes": 1
        },
        "collision_shape": (func():
            var s = RectangleShape2D.new()
            s.size = Vector2(12, 12)
            return s
        ).call(),
        "components": [config]
    }, "Chair")
```

#### Testing Steps
1. Apple Creation
   ```gdscript
   # Create apple
   var apple = ItemFactory.create_apple()
   add_child(apple)
   
   # Set breakpoint after creation
   # Verify:
   # - Sprite setup
   # - Collision shape
   # - Component added
   ```

2. Chair Creation
   ```gdscript
   # Create chair
   var chair = ItemFactory.create_chair()
   add_child(chair)
   
   # Verify:
   # - Correct texture
   # - Collision area
   # - Sittable component
   ```

### 3. Scene Conversion

#### Apple Scene
1. Create Test Scene
```gdscript
# test_apple_migration.gd
extends Node2D

func _ready() -> void:
    # Create old apple
    var old_apple = preload("res://src/field/items/apple.tscn").instantiate()
    add_child(old_apple)
    old_apple.position = Vector2(100, 100)
    
    # Create new apple
    var new_apple = ItemFactory.create_apple()
    add_child(new_apple)
    new_apple.position = Vector2(200, 100)
    
    # Set breakpoint here
    # Compare:
    # - Visual appearance
    # - Collision shapes
    # - Available interactions
```

#### Testing Steps
1. Visual Comparison
   - Check sprite appearance
   - Verify animations
   - Compare collision areas

2. Functional Testing
   ```gdscript
   # Test interaction
   var interactor = create_test_interactor()
   
   # Test old apple
   interactor.interact_with(old_apple)
   # Verify behavior
   
   # Test new apple
   interactor.interact_with(new_apple)
   # Verify same behavior
   ```

### 4. Field Integration

#### Implementation
```gdscript
# field.gd
class_name Field

func spawn_item(factory_method: Callable, position: Vector2) -> void:
    var item = factory_method.call()
    item.position = position
    add_child(item)

# Usage example:
field.spawn_item(ItemFactory.create_apple, Vector2(100, 100))
```

#### Testing Steps
1. Spawning
   ```gdscript
   # Test various spawn locations
   field.spawn_item(ItemFactory.create_apple, Vector2(100, 100))
   field.spawn_item(ItemFactory.create_chair, Vector2(200, 100))
   
   # Verify:
   # - Items placed correctly
   # - Proper scene hierarchy
   # - Interactions work
   ```

2. Runtime Testing
   ```gdscript
   # Test dynamic creation
   for i in range(5):
       field.spawn_item(ItemFactory.create_apple, 
           Vector2(100 + i * 50, 100))
   
   # Verify:
   # - Performance
   # - Memory usage
   # - Cleanup
   ```

## Integration Testing

### Test Scene Setup
1. Create comprehensive test scene:
   - Multiple item types
   - Various positions
   - Different interactions

### Migration Verification
1. Functionality Check
   ```gdscript
   # Compare behaviors
   func test_item_behavior(old_item, new_item, interactor):
       # Test old item
       var old_result = interact_and_record(old_item, interactor)
       
       # Test new item
       var new_result = interact_and_record(new_item, interactor)
       
       # Compare results
       assert_results_match(old_result, new_result)
   ```

2. Performance Testing
   ```gdscript
   # Measure creation time
   var start_time = Time.get_ticks_usec()
   var item = ItemFactory.create_apple()
   var creation_time = Time.get_ticks_usec() - start_time
   
   # Compare with old system
   start_time = Time.get_ticks_usec()
   var old_item = preload("res://src/field/items/apple.tscn").instantiate()
   var old_creation_time = Time.get_ticks_usec() - start_time
   ```

## Success Criteria

### Technical
- [ ] All items converted
- [ ] Factory methods working
- [ ] Configurations correct
- [ ] Performance maintained

### Functional
- [ ] Visual parity
- [ ] Behavior matches
- [ ] Interactions work
- [ ] Events properly emitted

## Cleanup

### 1. Remove Old Files
- [ ] apple.tscn
- [ ] chair.tscn
- [ ] Old component scripts
- [ ] Unused resources

### 2. Update References
- [ ] Update spawn points
- [ ] Fix factory calls
- [ ] Update documentation

### 3. Verify Removal
```gdscript
# Test removed file access
func test_cleanup():
    var old_scene = load("res://src/field/items/apple.tscn")
    assert(old_scene == null, "Old scene still accessible")
```

## Next Steps

1. Documentation
   - Update tutorials
   - Add migration guide
   - Document factory methods

2. Optimization
   - Profile performance
   - Memory usage analysis
   - Resource cleanup

3. Future Improvements
   - Editor integration
   - Visual configuration
   - Runtime modifications
