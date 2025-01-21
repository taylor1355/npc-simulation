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
	
	# Set position
	item.position = position
	
	# Set config (will be fully initialized in _ready)
	item.config = config
	
	return item

static func create_apple(gameboard: Gameboard, position: Vector2i) -> BaseItem:
	var config = preload("res://src/field/items/configs/apple_config.tres")
	return create_item(config, gameboard, position)

static func create_chair(gameboard: Gameboard, position: Vector2i) -> BaseItem:
	var config = preload("res://src/field/items/configs/chair_config.tres") 
	return create_item(config, gameboard, position)
