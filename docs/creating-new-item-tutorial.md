# Tutorial: Creating a New Item

This tutorial walks through creating a new consumable item (a cookie) that affects NPC needs.

## 1. Create Scene Files

Create two new scenes in `src/field/items/`:
```
cookie.tscn         # Main item scene
cookie_animation.tscn  # Visual/collision setup
```

## 2. Set Up Animation Scene

1. Create cookie_animation.tscn:
```
StaticAnimation (Node2D)
├── AnimationPlayer
├── GFX
│   ├── Sprite
│   │   └── Texture: cookie sprite
│   ├── Shadow
│   │   └── Texture: shadow sprite
│   └── ClickArea (Area2D)
│       └── CollisionShape2D
│           └── Shape: CircleShape2D (radius 7.0)
└── CollisionArea (Area2D)
    └── CollisionShape2D
        └── Shape: CircleShape2D (radius 6.5)
```

2. Configure collision layers:
```
ClickArea: Layer 0x4 (Click)
CollisionArea: Layer 0x1 (Gamepiece)
```

## 3. Set Up Main Scene

1. Create cookie.tscn:
```
Cookie (inherits gamepiece.tscn)
├── Decoupler (from parent)
├── Animation (instance cookie_animation.tscn)
└── ItemController
    └── Components (added in script)
```

2. Create cookie_controller.gd:
```gdscript
extends "res://src/field/items/item_controller.gd"

func _ready():
    super._ready()
    
    # Add consumable component
    var consumable = preload("res://src/field/items/components/consumable.gd").new()
    consumable.need_deltas = {
        "hunger": 40.0,
        "energy": 20.0
    }
    consumable.consumption_time = 3.0
    add_child(consumable)
```

## 4. Test the Item

1. Add to Scene:
```gdscript
# In field.gd or test scene
var cookie = preload("res://src/field/items/cookie.tscn").instantiate()
cookie.position = Vector2(100, 100)
add_child(cookie)
```

2. Verify:
- Cookie appears in world
- NPCs can interact with it
- Consuming affects needs
- Item destroyed at 0%

## Next Steps

1. Try modifying:
- Need delta values
- Consumption time
- Collision shape size
- Visual appearance

2. Add features:
- New components
- Custom interactions
- Special effects

For more details see:
- items.md: Component system
- interaction.md: Interaction system
- gamepiece.md: Base entity system
