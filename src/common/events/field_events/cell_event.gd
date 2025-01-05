class_name CellEvent extends Event

## Event for cell-related actions (highlighting, selection)
var cell: Vector2i

func _init(type: Type, cell_pos: Vector2i) -> void:
	super(type)
	cell = cell_pos

static func create_highlight(cell_pos: Vector2i) -> CellEvent:
	return CellEvent.new(Type.CELL_HIGHLIGHTED, cell_pos)

static func create_select(cell_pos: Vector2i) -> CellEvent:
	return CellEvent.new(Type.CELL_SELECTED, cell_pos)
