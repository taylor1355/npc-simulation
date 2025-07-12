class_name GamepieceEvents extends RefCounted

## Collection of gamepiece-related event classes

class CellChangedEvent extends Event:
	var gamepiece: Gamepiece
	var old_cell: Vector2i
	
	func _init(piece: Gamepiece, old_pos: Vector2i) -> void:
		super(Type.GAMEPIECE_CELL_CHANGED)
		gamepiece = piece
		old_cell = old_pos

class PathSetEvent extends Event:
	var gamepiece: Gamepiece
	var destination_cell: Vector2i
	
	func _init(piece: Gamepiece, dest_pos: Vector2i) -> void:
		super(Type.GAMEPIECE_PATH_SET)
		gamepiece = piece
		destination_cell = dest_pos

class ClickedEvent extends Event:
	var gamepiece: Gamepiece
	var ui_element_id: String = ""  # Optional UI element that was clicked
	
	func _init(piece: Gamepiece, p_ui_element_id: String = "") -> void:
		super(Type.GAMEPIECE_CLICKED)
		gamepiece = piece
		ui_element_id = p_ui_element_id

class DestroyedEvent extends Event:
	var gamepiece: Gamepiece
	
	func _init(piece: Gamepiece) -> void:
		super(Type.GAMEPIECE_DESTROYED)
		gamepiece = piece

class FocusedEvent extends Event:
	var gamepiece: Gamepiece
	
	func _init(piece: Gamepiece) -> void:
		super(Type.FOCUSED_GAMEPIECE_CHANGED)
		gamepiece = piece

class HoverStartedEvent extends Event:
	var gamepiece: Gamepiece
	var ui_element_id: String = ""  # Optional UI element that was hovered
	
	func _init(piece: Gamepiece, p_ui_element_id: String = "") -> void:
		super(Type.GAMEPIECE_HOVER_STARTED)
		gamepiece = piece
		ui_element_id = p_ui_element_id

class HoverEndedEvent extends Event:
	var gamepiece: Gamepiece
	var ui_element_id: String = ""  # Optional UI element that was unhovered
	
	func _init(piece: Gamepiece, p_ui_element_id: String = "") -> void:
		super(Type.GAMEPIECE_HOVER_ENDED)
		gamepiece = piece
		ui_element_id = p_ui_element_id

## Static factory methods
static func create_cell_changed(piece: Gamepiece, old_pos: Vector2i) -> CellChangedEvent:
	return CellChangedEvent.new(piece, old_pos)

static func create_path_set(piece: Gamepiece, dest_pos: Vector2i) -> PathSetEvent:
	return PathSetEvent.new(piece, dest_pos)

static func create_clicked(piece: Gamepiece, ui_element_id: String = "") -> ClickedEvent:
	return ClickedEvent.new(piece, ui_element_id)

static func create_destroyed(piece: Gamepiece) -> DestroyedEvent:
	return DestroyedEvent.new(piece)

static func create_focused(piece: Gamepiece) -> FocusedEvent:
	return FocusedEvent.new(piece)

static func create_hover_started(piece: Gamepiece, ui_element_id: String = "") -> HoverStartedEvent:
	return HoverStartedEvent.new(piece, ui_element_id)

static func create_hover_ended(piece: Gamepiece, ui_element_id: String = "") -> HoverEndedEvent:
	return HoverEndedEvent.new(piece, ui_element_id)
