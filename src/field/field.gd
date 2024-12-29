extends Node2D

@export var focused_game_piece: Gamepiece = null:
	set = set_focused_game_piece

@export var gameboard: Gameboard


func _ready() -> void:
	assert(gameboard)
	randomize()

	FieldEvents.gamepiece_clicked.connect(_on_gamepiece_clicked)
	
	# The field state must pause/unpause with combat accordingly.
	# Note that pausing/unpausing input is already wrapped up in triggers, which are what will initiate combat.
	
	Camera.scale = scale
	Camera.gameboard = gameboard
	Camera.make_current()
	Camera.reset_position()


# func _unhandled_key_input(event: InputEvent) -> void:
	# if event.is_action_pressed("pause"):
	# 	FieldEvents.input_paused.emit(true)
	# 	print("Field paused")
	# elif event.is_action_released("pause"):
	# 	FieldEvents.input_paused.emit(false)
	# 	print("Field unpaused")

func _on_gamepiece_clicked(gamepiece: Gamepiece) -> void:
	set_focused_game_piece(gamepiece)


func set_focused_game_piece(value: Gamepiece) -> void:
	Camera.anchored = true

	if value == focused_game_piece:
		return

	focused_game_piece = value
	
	if not is_inside_tree():
		await ready
	
	Camera.gamepiece = focused_game_piece

	FieldEvents.focused_gamepiece_changed.emit(focused_game_piece)
