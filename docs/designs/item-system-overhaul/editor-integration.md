# Editor Integration Design

## Problem
We need a clean way to place and configure items in the Godot editor that:
- Shows correct visual previews
- Uses our ItemConfig resource system
- Works consistently between editor and runtime
- Integrates well with existing systems

## Current Architecture Review

### Item Configuration
- ItemConfig resources define item properties
- Components configured through ItemComponentConfig
- Factory creates items from configs at runtime

### Base Infrastructure  
- BaseItem scene provides core structure
- ItemController manages components
- Factory handles instantiation and setup

## Design Options

### Option 1: EditorItem Node
Pros:
- Direct placement in editor
- Immediate visual feedback
Cons:
- Duplicates factory logic
- Separate path for editor vs runtime
- More complex maintenance

### Option 2: Scene Instantiation
Pros:
- Single source of truth (factory)
- Consistent behavior
Cons:
- No live preview
- Less intuitive placement

### Option 3: Enhanced BaseItem ✓
Pros:
- Single implementation
- Clean editor integration
- Consistent behavior
- Leverages existing systems

## Proposed Solution: Enhanced BaseItem

### 1. Extend BaseItem
```gdscript
# base_item.gd
@tool
class_name BaseItem

@export var config: ItemConfig:
    set(value):
        config = value
        if Engine.is_editor_hint():
            _update_editor_visuals()

func _ready() -> void:
    # ... existing setup ...
    
    if Engine.is_editor_hint():
        # Update visuals when node enters tree in editor
        if config:
            _update_editor_visuals()
    else:
        # Initialize item at runtime
        if config:
            _initialize_item()

func _update_editor_visuals() -> void:
    # Update visual properties for editor preview
    if not config or not is_node_ready():
        return
        
    # Update sprite
    if sprite and config.sprite_texture:
        sprite.texture = config.sprite_texture
        sprite.hframes = config.sprite_hframes
        sprite.vframes = config.sprite_vframes
        sprite.frame = config.sprite_frame
    
    # Update collision
    if collision_shape and config.collision_shape:
        collision_shape.shape = config.collision_shape
        
    # Update node name
    if config.item_name:
        name = config.item_name

func _initialize_item() -> void:
    # Full runtime initialization
    if not config or not is_node_ready():
        return
        
    # Set up visuals
    _update_editor_visuals()
    
    # Set display name
    display_name = config.item_name
    
    # Initialize components
    for component_config in config.components:
        item_controller.add_component(component_config)
```

Key Improvements:
1. Clear function names that describe their purpose
2. Explicit separation of editor and runtime behavior
3. Guaranteed runtime initialization in _ready()
4. Editor updates on both config changes and node ready
5. Proper node readiness checks

### 2. Update Factory
```gdscript
# item_factory.gd
static func create_item(config: ItemConfig, gameboard: Gameboard, position: Vector2i) -> BaseItem:
    # Validate config
    if not config._validate():
        push_error("Invalid item configuration")
        return null
        
    var item = BASE_ITEM_SCENE.instantiate() as BaseItem
    
    # Set required gameboard reference
    item.gameboard = gameboard
    
    # Set position
    item.position = position
    
    # Set config (will be fully initialized in _ready)
    item.config = config
    
    return item
```

### Benefits

1. Editor Integration
- Place BaseItem nodes directly
- Assign configs in inspector
- Immediate visual feedback
- No special editor node needed

2. Runtime Behavior
- Factory uses same base scene
- Config triggers appropriate setup
- Components only added at runtime
- Consistent with editor items

3. Maintenance
- Single implementation to maintain
- Clear separation of editor/runtime
- Leverages existing systems
- Easy to extend

### Implementation Steps

1. Update BaseItem
- Add tool annotation
- Add config property
- Implement configuration logic
- Test editor preview

2. Update Factory
- Verify compatibility
- Test runtime creation
- Validate component setup

3. Migration
- Update existing items
- Remove old scenes
- Document new workflow

### Usage Example

1. Editor Placement:
```
- Add BaseItem to scene
- Set ItemConfig in inspector
- See immediate preview
- Position as needed
```

2. Runtime Creation:
```gdscript
var item = ItemFactory.create_item(config, ...)
# Works same as editor-placed items
```

## Success Criteria

1. Technical
- [ ] Live preview in editor
- [ ] Consistent runtime behavior
- [ ] Clean component integration
- [ ] Type safety maintained

2. Workflow
- [ ] Intuitive item placement
- [ ] Clear configuration
- [ ] Reliable previews
- [ ] Easy migration

## Next Steps

1. Implementation
- Update BaseItem script
- Test editor integration
- Verify runtime behavior
- Document workflow

2. Migration
- Convert existing items
- Update factory usage
- Remove old scenes
- Update docs
