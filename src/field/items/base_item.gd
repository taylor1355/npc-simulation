@tool
class_name BaseItem
extends Gamepiece

@onready var sprite: Sprite2D = $Animation/GFX/Sprite
@onready var collision_shape: CollisionShape2D = $Animation/CollisionArea/CollisionShape2D
@onready var item_controller: ItemController = $ItemController

@export var config: ItemConfig:
	set(value):
		config = value
		if Engine.is_editor_hint():
			_update_editor_visuals()

func _ready() -> void:
	super._ready()
	# Verify required nodes exist
	assert(sprite != null, "Sprite node missing")
	assert(collision_shape != null, "CollisionShape node missing")
	assert(item_controller != null, "ItemController node missing")
	
	# Items block movement by default
	blocks_movement = true
	
	if Engine.is_editor_hint():
		# Update visuals when node enters tree in editor
		if config:
			_update_editor_visuals()
	else:
		# Initialize item at runtime
		if config:
			_initialize_item()

func _update_editor_visuals() -> void:
	if not config or not is_node_ready():
		return
		
	# Update sprite
	if sprite and config.sprite_texture:
		sprite.texture = config.sprite_texture
		sprite.hframes = config.sprite_hframes
		sprite.vframes = config.sprite_vframes
		sprite.frame = config.sprite_frame
	
	# Update collision and click area
	if collision_shape and config.collision_shape:
		collision_shape.shape = config.collision_shape
		
		# Set up click area (slightly larger than collision)
		var click_shape = config.collision_shape.duplicate()
		if click_shape is CircleShape2D:
			click_shape.radius += 1.0
		elif click_shape is RectangleShape2D:
			click_shape.size += Vector2(2, 2)
		
		$Animation/GFX/ClickArea/CollisionShape2D.shape = click_shape
		
	# Update node name
	if config.item_name:
		name = config.item_name

func _initialize_item() -> void:
	if not config or not is_node_ready():
		return
		
	# Set up visuals
	_update_editor_visuals()
	
	# Set display name
	display_name = config.item_name
	
	# Initialize components
	for component_config in config.components:
		item_controller.add_component(component_config)
