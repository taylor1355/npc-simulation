class_name EventBus extends Node

## Bus that handles event dispatching
## - event types improve maintainability over using raw signals

func _init() -> void:
	pass

signal event_dispatched(event: Event)

# Specific signals for each event type
signal cell_highlighted(event: CellEvent)
signal cell_selected(event: CellEvent)
signal gamepiece_cell_changed(event: GamepieceEvents.CellChangedEvent)
signal gamepiece_path_set(event: GamepieceEvents.PathSetEvent)
signal gamepiece_clicked(event: GamepieceEvents.ClickedEvent)
signal gamepiece_destroyed(event: GamepieceEvents.DestroyedEvent)
signal npc_need_changed(event: NpcEvents.NeedChangedEvent)
signal focused_gamepiece_changed(event: GamepieceEvents.FocusedEvent)
signal terrain_changed(event: Event)
signal input_paused(is_paused: bool)

# Cell change tracking
var _cell_changes_this_frame: Array[Vector2i] = []

func _ready() -> void:
	# Connect to our own signal to track cell changes
	event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.GAMEPIECE_CELL_CHANGED):
				var gp_event := event as GamepieceEvents.CellChangedEvent
				_cell_changes_this_frame.append(gp_event.gamepiece.cell)
	)
	set_process_priority(99999999)  # Run last in frame

func _process(_delta: float) -> void:
	_cell_changes_this_frame.clear()

## Dispatch an event to all listeners
func dispatch(event: Event) -> void:
	event_dispatched.emit(event)
	
	# Emit type-specific signal
	match event.event_type:
		Event.Type.CELL_HIGHLIGHTED:
			cell_highlighted.emit(event as CellEvent)
		Event.Type.CELL_SELECTED:
			cell_selected.emit(event as CellEvent)
		Event.Type.GAMEPIECE_CELL_CHANGED:
			gamepiece_cell_changed.emit(event as GamepieceEvents.CellChangedEvent)
		Event.Type.GAMEPIECE_PATH_SET:
			gamepiece_path_set.emit(event as GamepieceEvents.PathSetEvent)
		Event.Type.GAMEPIECE_CLICKED:
			gamepiece_clicked.emit(event as GamepieceEvents.ClickedEvent)
		Event.Type.GAMEPIECE_DESTROYED:
			gamepiece_destroyed.emit(event as GamepieceEvents.DestroyedEvent)
		Event.Type.NPC_NEED_CHANGED:
			npc_need_changed.emit(event as NpcEvents.NeedChangedEvent)
		Event.Type.FOCUSED_GAMEPIECE_CHANGED:
			focused_gamepiece_changed.emit(event as GamepieceEvents.FocusedEvent)
		Event.Type.TERRAIN_CHANGED:
			terrain_changed.emit(event)
		Event.Type.INPUT_PAUSED:
			input_paused.emit(event.get("is_paused"))

## Check if a gamepiece moved to a cell this frame
func did_gp_move_to_cell_this_frame(cell: Vector2i) -> bool:
	return _cell_changes_this_frame.has(cell)
