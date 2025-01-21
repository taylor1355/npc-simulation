class_name ItemsManager
extends Node2D

var gameboard: Gameboard

func _ready() -> void:
	y_sort_enabled = true

func spawn_item(item: BaseItem) -> void:
	add_child(item)

func get_random_position() -> Vector2i:
	# Get random cell within boundaries
	var x = randi_range(gameboard.boundaries.position.x, gameboard.boundaries.end.x - 1)
	var y = randi_range(gameboard.boundaries.position.y, gameboard.boundaries.end.y - 1)
	var cell = Vector2i(x, y)
	
	# Convert cell to pixel coordinates
	return gameboard.cell_to_pixel(cell)

func spawn_apple() -> void:
	var pos = get_random_position()
	var apple = ItemFactory.create_apple(gameboard, pos)
	spawn_item(apple)

func spawn_chair() -> void:
	var pos = get_random_position()
	var chair = ItemFactory.create_chair(gameboard, pos)
	spawn_item(chair)
