extends Node2D

@export var focused_game_piece: Gamepiece = null:
	set = set_focused_game_piece

@export var gameboard: Gameboard


func _init() -> void:
	# Initialize shared NPC client first
	Globals.npc_client = NpcClient.new()
	add_child(Globals.npc_client)


func _ready() -> void:
	assert(gameboard)
	randomize()

	FieldEvents.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.GAMEPIECE_CLICKED):
				_on_gamepiece_clicked(event as GamepieceEvents.ClickedEvent)
	)
	
	# The field state must pause/unpause with combat accordingly.
	# Note that pausing/unpausing input is already wrapped up in triggers, which are what will initiate combat.
	
	Camera.scale = scale
	Camera.gameboard = gameboard
	Camera.make_current()
	Camera.reset_position()


# func _unhandled_key_input(event: InputEvent) -> void:
	# if event.is_action_pressed("pause"):
	# 	FieldEvents.dispatch(SystemEvents.create_input_paused(true))
	# 	print("Field paused")
	# elif event.is_action_released("pause"):
	# 	FieldEvents.dispatch(SystemEvents.create_input_paused(false))
	# 	print("Field unpaused")

func _on_gamepiece_clicked(event: GamepieceEvents.ClickedEvent) -> void:
	set_focused_game_piece(event.gamepiece)


func set_focused_game_piece(value: Gamepiece) -> void:
	Camera.anchored = true

	if value == focused_game_piece:
		return

	focused_game_piece = value
	
	if not is_inside_tree():
		await ready
	
	Camera.gamepiece = focused_game_piece

	FieldEvents.dispatch(
		GamepieceEvents.create_focused(focused_game_piece)
	)
