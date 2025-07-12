extends Node2D

@export var focused_game_piece: Gamepiece = null:
	set = set_focused_game_piece

@export var gameboard: Gameboard

@onready var items_manager: Node2D = $Entities/Items


func _init() -> void:
	# Initialize shared NPC client first using factory
	Globals.npc_client = NpcClientFactory.get_shared_client()
	add_child(Globals.npc_client)


func _ready() -> void:
	assert(gameboard)
	randomize()
	
	# Set up items manager
	items_manager.gameboard = gameboard
	
	# Spawn initial items
	items_manager.spawn_chair()
	items_manager.spawn_apple()

	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.GAMEPIECE_DESTROYED):
				if event.gamepiece == focused_game_piece:
					set_focused_game_piece(null)
	)
	
	# The field state must pause/unpause with combat accordingly.
	# Note that pausing/unpausing input is already wrapped up in triggers, which are what will initiate combat.
	
	# Setup camera with field parameters
	Camera.setup_from_field(scale, gameboard)
	
	# Wait a frame for NPCs to initialize
	await get_tree().process_frame
	
	# Emit initial focus event if there's a focused gamepiece
	if focused_game_piece:
		EventBus.dispatch(
			GamepieceEvents.create_focused(focused_game_piece)
		)

func set_focused_game_piece(value: Gamepiece) -> void:
	if value == focused_game_piece:
		return

	focused_game_piece = value
	
	if not is_inside_tree():
		await ready

	EventBus.dispatch(
		GamepieceEvents.create_focused(focused_game_piece)
	)
