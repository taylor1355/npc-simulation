class_name ItemFactory

const BASE_ITEM_SCENE = preload("res://src/field/items/base_item.tscn")

static func create_item(config: ItemConfig, gameboard: Gameboard, position: Vector2i = Vector2i.ZERO) -> BaseItem:
	# Validate config
	if not config._validate():
		push_error("Invalid item configuration")
		return null
		
	var item := BASE_ITEM_SCENE.instantiate() as BaseItem
	
	# Set required gameboard reference
	item.gameboard = gameboard
	
	# Configure sprite
	var sprite = item.get_node("Animation/GFX/Sprite")
	sprite.texture = config.sprite_texture
	sprite.hframes = config.sprite_hframes
	sprite.vframes = config.sprite_vframes
	sprite.frame = config.sprite_frame
	
	# Configure collision
	var collision_shape = config.collision_shape
	
	# Set up click area (slightly larger than collision)
	var click_shape = collision_shape.duplicate()
	if click_shape is CircleShape2D:
		click_shape.radius += 1.0
	elif click_shape is RectangleShape2D:
		click_shape.size += Vector2(2, 2)
	
	item.get_node("Animation/GFX/ClickArea/CollisionShape2D").shape = click_shape
	item.get_node("Animation/CollisionArea/CollisionShape2D").shape = collision_shape
	
	# Add components
	var controller = item.get_node("ItemController") as ItemController
	for component_config in config.components:
		controller.add_component(component_config)
	
	# Set display name from config
	item.display_name = config.item_name
	
	# Set position
	item.position = position
	
	return item

static func create_apple(gameboard: Gameboard, position: Vector2i) -> BaseItem:
	var config = preload("res://src/field/items/configs/apple_config.tres")
	return create_item(config, gameboard, position)

static func create_chair(gameboard: Gameboard, position: Vector2i) -> BaseItem:
	var config = preload("res://src/field/items/configs/chair_config.tres") 
	return create_item(config, gameboard, position)
