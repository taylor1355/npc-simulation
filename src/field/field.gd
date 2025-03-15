extends Node2D

@export var focused_game_piece: Gamepiece = null:
	set = set_focused_game_piece

@export var gameboard: Gameboard

@onready var items_manager: Node2D = $Entities/Items


func _init() -> void:
	# Initialize shared NPC client first
	Globals.npc_client = MockNpcClient.new()
	add_child(Globals.npc_client)


func _ready() -> void:
	assert(gameboard)
	randomize()
	
	# Set up items manager
	items_manager.gameboard = gameboard
	
	# Spawn initial items
	items_manager.spawn_chair()
	items_manager.spawn_apple()

	FieldEvents.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.GAMEPIECE_CLICKED):
				_on_gamepiece_clicked(event as GamepieceEvents.ClickedEvent)
			elif event.is_type(Event.Type.GAMEPIECE_DESTROYED):
				if event.gamepiece == focused_game_piece:
					set_focused_game_piece(null)
	)
	
	# The field state must pause/unpause with combat accordingly.
	# Note that pausing/unpausing input is already wrapped up in triggers, which are what will initiate combat.
	
	Camera.scale = scale
	Camera.gameboard = gameboard
	Camera.make_current()
	Camera.reset_position()
	
	# Wait a frame for NPCs to initialize
	await get_tree().process_frame
	
	# Emit initial focus event if there's a focused gamepiece
	if focused_game_piece:
		FieldEvents.dispatch(
			GamepieceEvents.create_focused(focused_game_piece)
		)


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
