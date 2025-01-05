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
	
	func _init(piece: Gamepiece) -> void:
		super(Type.GAMEPIECE_CLICKED)
		gamepiece = piece

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

## Static factory methods
static func create_cell_changed(piece: Gamepiece, old_pos: Vector2i) -> CellChangedEvent:
	return CellChangedEvent.new(piece, old_pos)

static func create_path_set(piece: Gamepiece, dest_pos: Vector2i) -> PathSetEvent:
	return PathSetEvent.new(piece, dest_pos)

static func create_clicked(piece: Gamepiece) -> ClickedEvent:
	return ClickedEvent.new(piece)

static func create_destroyed(piece: Gamepiece) -> DestroyedEvent:
	return DestroyedEvent.new(piece)

static func create_focused(piece: Gamepiece) -> FocusedEvent:
	return FocusedEvent.new(piece)
