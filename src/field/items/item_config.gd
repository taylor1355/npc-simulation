@tool
class_name ItemConfig
extends Resource

# Item name
@export var item_name: String = ""

# Sprite configuration
@export var sprite_texture: Texture2D
@export var sprite_hframes: int = 1
@export var sprite_vframes: int = 1
@export var sprite_frame: int = 0

# Collision configuration
@export var collision_shape: Shape2D

# Components
@export var components: Array[ItemComponentConfig] = []

func _validate() -> bool:
    if not item_name:
        push_error("Item name not set")
        return false
        
    if not sprite_texture:
        push_error("Sprite texture not set")
        return false
        
    if not collision_shape:
        push_error("Collision shape not set")
        return false
        
    # Validate all component configs
    for component in components:
        if not component._validate():
            return false
            
    return true
