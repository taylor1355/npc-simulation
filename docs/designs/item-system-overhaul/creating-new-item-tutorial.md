# Creating New Items Tutorial

This tutorial demonstrates how to create new items using the improved item system. While development is ongoing, it also serves as a source of requirements.

## 1. Create Component Configuration

First, create a resource file for your item's components:

```gdscript
# cookie_config.tres
@tool
extends ItemComponentConfig

# Configure in the editor:
component_script = preload("res://src/field/items/components/consumable_component.gd")
properties = {
    "consumption_time": 3.0,
    "need_deltas": {
        "hunger": 40.0,
        "energy": 20.0
    }
}
```

## 2. Add Factory Method

Add a creation method to ItemFactory:

```gdscript
static func create_cookie() -> Node:
    var config = preload("res://src/field/items/configs/cookie_config.tres")
    return create_item({
        "sprite_config": {
            "texture": preload("res://assets/sprites/cookie.png"),
            "hframes": 1  # Only needed for spritesheets
        },
        "collision_shape": (func(): var s = CircleShape2D.new(); s.radius = 6.5; return s).call(),
        "components": [config]
    }, "Cookie")
```

## 3. Using the Item

```gdscript
# Spawn at specific position
field.add_item(ItemFactory.create_cookie(), Vector2(100, 100))

# Or add to automatic spawning
field.spawn_item(ItemFactory.create_cookie)
```

## Component Types

### ConsumableComponent
```gdscript
properties = {
    "need_deltas": {  # Changes when consumed
        "hunger": 40.0,
        "energy": 20.0
    },
    "consumption_time": 3.0  # Seconds to consume
}
```

### SittableComponent
```gdscript
properties = {
    "need_rates": {  # Changes per second
        "energy": 10.0
    }
}
```

## Tips

1. **Sprite Configuration**
   - Use "hframes" for spritesheets
   - Set initial "frame" if needed
   - Texture is required

2. **Collision Shapes**
   - CircleShape2D for round items
   - RectangleShape2D for furniture
   - Click area automatically sized slightly larger

3. **Components**
   - Multiple components supported
   - Properties copied on creation
   - Components auto-register with controller

## Example: Apple Implementation

```gdscript
# configs/consumable_apple_config.tres
@tool
extends ItemComponentConfig

component_script = preload("res://src/field/items/components/consumable_component.gd")
properties = {
    "consumption_time": 5.0,
    "need_deltas": {
        "hunger": 25.0
    }
}

# item_factory.gd
static func create_apple() -> Node:
    var config = preload("res://src/field/items/configs/consumable_apple_config.tres")
    return create_item({
        "sprite_config": {
            "texture": preload("res://assets/sprites/apple_spritesheet.png"),
            "hframes": 8,
            "frame": 0
        },
        "collision_shape": (func(): var s = CircleShape2D.new(); s.radius = 6.5; return s).call(),
        "components": [config]
    }, "Apple")
```
