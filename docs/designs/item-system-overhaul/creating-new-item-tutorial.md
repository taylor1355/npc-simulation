# Creating New Items Tutorial

This tutorial demonstrates how to create new items using the config-based item system.

## 1. Create Item Configuration

Create a new resource file (*.tres) in src/field/items/configs/:

```gdscript
# cookie_config.tres
@tool
extends ItemConfig

# Configure in inspector:
item_name = "Cookie"
sprite_texture = preload("res://assets/sprites/cookie.png")
sprite_hframes = 1
collision_shape = CircleShape2D.new()  # Set radius in inspector
```

## 2. Add Component Configuration

Add components through the inspector:
1. Create new ItemComponentConfig
2. Set component_script (e.g., ConsumableComponent)
3. Configure properties dictionary
4. Add to components array

## Common Component Properties

### ConsumableComponent
```
properties = {
    "need_deltas": {  # Changes when consumed
        "hunger": 40.0,
        "energy": 20.0
    },
    "consumption_time": 3.0  # Seconds to consume
}
```

### SittableComponent
```
properties = {
    "need_rates": {  # Changes per second
        "energy": 10.0
    }
}
```

## 3. Using the Item

### Editor Placement
1. Add BaseItem node to scene
2. Assign config in inspector
3. Position as needed
4. See immediate preview

### Runtime Spawning
```gdscript
# Add factory helper
static func create_cookie(gameboard: Gameboard, position: Vector2i) -> BaseItem:
    var config = preload("res://src/field/items/configs/cookie_config.tres")
    return create_item(config, gameboard, position)

# Usage
var cookie = ItemFactory.create_cookie(gameboard, Vector2i(10, 10))
```

## Tips

1. **Visual Setup**
   - Preview updates live in editor
   - Sprite frames for animations
   - Collision shape affects click area

2. **Component Configuration**
   - Components initialize at runtime
   - Properties validated on load
   - Clean separation of config/behavior

3. **Best Practices**
   - One config per item type
   - Clear, descriptive names
   - Reuse components when possible
   - Test in editor before runtime

## Example: Apple Configuration

```gdscript
# apple_config.tres
@tool
extends ItemConfig

item_name = "Apple"
sprite_texture = preload("res://assets/sprites/apple_spritesheet.png")
sprite_hframes = 8
sprite_frame = 0
collision_shape = CircleShape2D.new()  # radius = 6.5

# Component config in inspector:
components = [
    {
        component_script = ConsumableComponent,
        properties = {
            "consumption_time": 5.0,
            "need_deltas": {
                "hunger": 25.0
            }
        }
    }
]
