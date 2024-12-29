extends Sprite2D

@export var gameboard: Gameboard

var focused_gamepiece: Gamepiece = null


func _ready() -> void:
	FieldEvents.gamepiece_path_set.connect(_on_gamepiece_path_set)
	FieldEvents.focused_gamepiece_changed.connect(_on_focused_gamepiece_changed)


func _on_gamepiece_path_set(gamepiece: Gamepiece, destination_cell: Vector2i) -> void:
	if gamepiece != Globals.focused_gamepiece:
		return

	gamepiece.arrived.connect(hide, CONNECT_ONE_SHOT)
	position = gameboard.cell_to_pixel(destination_cell)
	show()


func _on_focused_gamepiece_changed(gamepiece: Gamepiece) -> void:
	if focused_gamepiece:
		focused_gamepiece.arrived.disconnect(hide)
	focused_gamepiece = gamepiece

	focused_gamepiece.arrived.connect(hide, CONNECT_ONE_SHOT)

	var path_curve = focused_gamepiece._path.curve
	if path_curve:
		position = path_curve.get_baked_points()[-1]
		show()
	else:
		push_warning("No path points found for focused gamepiece.")
		hide()
