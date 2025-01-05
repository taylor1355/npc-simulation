extends Sprite2D

@export var gameboard: Gameboard

var focused_gamepiece: Gamepiece = null


func _ready() -> void:
	FieldEvents.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.GAMEPIECE_PATH_SET):
				_on_gamepiece_path_set(event as GamepieceEvents.PathSetEvent)
			elif event.is_type(Event.Type.FOCUSED_GAMEPIECE_CHANGED):
				_on_focused_gamepiece_changed(event as GamepieceEvents.FocusedEvent)
	)


func _on_gamepiece_path_set(event: GamepieceEvents.PathSetEvent) -> void:
	if event.gamepiece != Globals.focused_gamepiece:
		return

	event.gamepiece.arrived.connect(hide, CONNECT_ONE_SHOT)
	position = gameboard.cell_to_pixel(event.destination_cell)
	show()


func _on_focused_gamepiece_changed(event: GamepieceEvents.FocusedEvent) -> void:
	if focused_gamepiece:
		focused_gamepiece.arrived.disconnect(hide)
	focused_gamepiece = event.gamepiece

	focused_gamepiece.arrived.connect(hide, CONNECT_ONE_SHOT)

	var path_curve = focused_gamepiece._path.curve
	if path_curve:
		position = path_curve.get_baked_points()[-1]
		show()
	else:
		push_warning("No path points found for focused gamepiece.")
		hide()
