# Sprite Layering System Design

## Problem Statement

Currently, the NPC simulation uses manual z-index manipulation to handle furniture interactions (e.g., NPCs sitting on chairs). This approach conflicts with Godot's Y-sorting system and causes rendering issues:

- Emoji states render behind other NPCs when sitting
- Z-index overrides Y-sorting, breaking depth perception
- NPCs sometimes appear behind furniture after standing up
- The system doesn't support complex occlusion scenarios (beds with sheets, showers, etc.)

## Proposed Solution

Implement a sprite layer system that splits furniture into multiple layers, allowing natural occlusion without z-index manipulation.

## Design Goals

1. **Natural Occlusion**: Characters should appear correctly layered with furniture parts
2. **Y-Sort Compatible**: Work seamlessly with Godot's Y-sorting system
3. **Extensible**: Easy to add new furniture types with complex layering
4. **Component-Based**: Integrate with existing component architecture
5. **Performance**: Maintain good performance with minimal overhead

## Technical Design

### Core Components

#### 1. LayeredItemConfig (extends ItemConfig)
```gdscript
class_name LayeredItemConfig extends ItemConfig

# Sprite layer definitions
@export var back_layers: Array[SpriteLayerConfig] = []
@export var front_layers: Array[SpriteLayerConfig] = []
@export var occlusion_zones: Array[OcclusionZone] = []

# Y-sort origin offset for proper depth sorting
@export var y_sort_offset: float = 0.0
```

#### 2. SpriteLayerConfig (Resource)
```gdscript
class_name SpriteLayerConfig extends Resource

@export var layer_name: String = ""
@export var sprite_texture: Texture2D
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var y_sort_offset: float = 0.0  # Per-layer y-sort adjustment
@export var opacity: float = 1.0
```

#### 3. LayeredSpriteComponent
```gdscript
class_name LayeredSpriteComponent extends ItemComponent

# Manages sprite layers and character insertion
var back_container: Node2D
var character_container: Node2D  
var front_container: Node2D

func insert_character(character: Node2D, layer_name: String = "default")
func remove_character(character: Node2D)
func get_insertion_position(layer_name: String) -> Vector2
```

### Scene Structure

```
FurnitureItem (Gamepiece)
├── Animation
│   └── GFX
│       ├── BackLayers (Node2D, y_sort_enabled=true)
│       │   ├── BedBase (Sprite2D)
│       │   └── Mattress (Sprite2D)
│       ├── CharacterLayer (Node2D, y_sort_enabled=true)
│       │   └── (NPCs inserted here during interaction)
│       └── FrontLayers (Node2D, y_sort_enabled=true)
│           ├── Sheets (Sprite2D)
│           └── Pillow (Sprite2D)
└── ItemController
    └── LayeredSpriteComponent
```

### Integration Points

#### 1. SittableComponent Refactor
```gdscript
# Remove z-index manipulation
# OLD:
participant._gamepiece.z_index = item_controller._gamepiece.z_index + 1

# NEW:
var layered_sprite = get_component(LayeredSpriteComponent)
if layered_sprite:
    layered_sprite.insert_character(participant._gamepiece, "seat")
```

#### 2. New Interaction Components
- **LyingComponent**: For beds, manages character position between layers
- **ShowerComponent**: Handles partial visibility with front layer opacity
- **SofaComponent**: Multi-character support with proper layering

### Implementation Examples

#### Chair Configuration
```
back_layers: [
  SpriteLayerConfig(name="chair_back", texture=chair_back.png)
]
front_layers: []  # Simple chairs don't need front layers
```

#### Bed Configuration
```
back_layers: [
  SpriteLayerConfig(name="bed_frame", texture=bed_frame.png),
  SpriteLayerConfig(name="mattress", texture=mattress.png)
]
front_layers: [
  SpriteLayerConfig(name="sheets", texture=sheets.png, opacity=0.9),
  SpriteLayerConfig(name="blanket", texture=blanket.png)
]
occlusion_zones: [
  OcclusionZone(name="lying", rect=Rect2(0, -10, 32, 48))
]
```

#### Shower Configuration
```
back_layers: [
  SpriteLayerConfig(name="shower_back", texture=shower_back.png)
]
front_layers: [
  SpriteLayerConfig(name="curtain", texture=curtain.png, opacity=0.7),
  SpriteLayerConfig(name="shower_door", texture=door.png)
]
occlusion_zones: [
  OcclusionZone(name="showering", rect=Rect2(0, 0, 32, 32), 
                character_offset=Vector2(0, 20))  # Show only head
]
```

## Migration Plan

### Phase 1: Core System
1. Implement LayeredItemConfig and SpriteLayerConfig
2. Create LayeredSpriteComponent
3. Update ItemFactory to support layered items
4. Create test furniture with layers

### Phase 2: Component Updates
1. Refactor SittableComponent to use layers
2. Remove all z-index manipulation
3. Test with existing chairs
4. Verify nameplate rendering

### Phase 3: New Furniture
1. Create bed sprites and LyingComponent
2. Create shower sprites and ShowerComponent
3. Add sofa with multi-character support
4. Document layer creation guidelines

### Phase 4: Polish
1. Add transition animations between layers
2. Optimize performance if needed
3. Create editor tools for layer preview
4. Update documentation

## Benefits

1. **Fixes Current Bugs**: Resolves emoji rendering and z-order issues
2. **Natural Visuals**: Characters appear correctly with furniture
3. **Extensible**: Easy to add new furniture types
4. **Maintainable**: No complex z-index management
5. **Reusable**: Components can be mixed and matched

## Risks and Mitigation

1. **Performance**: Multiple sprites per furniture
   - Mitigation: Use texture atlases, cull off-screen layers
   
2. **Art Requirements**: Need to split existing sprites
   - Mitigation: Start with new furniture, migrate old ones gradually
   
3. **Complexity**: More nodes in scene tree
   - Mitigation: Clear documentation, helper tools

## Alternatives Considered

1. **Pure Y-Sort Origin Manipulation**: Limited flexibility for complex occlusion
2. **Viewport-Based Rendering**: Overcomplicated for this use case
3. **Shader-Based Masking**: Performance concerns, harder to implement

## Success Criteria

- NPCs sitting on chairs render correctly with all other NPCs
- Nameplates/emojis always visible when appropriate
- Support for complex furniture (beds, showers, sofas)
- No z-index manipulation in codebase
- Maintains current performance levels