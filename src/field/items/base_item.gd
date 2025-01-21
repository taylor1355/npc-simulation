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
	
	# Items block movement by default
	blocks_movement = true
