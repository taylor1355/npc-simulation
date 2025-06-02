class_name VisionManager extends Area2D

var parent_gamepiece: Gamepiece
var seen_npcs: Dictionary[Gamepiece, NpcController] = {}
var seen_items: Dictionary[Gamepiece, ItemController] = {}


func _ready():
	parent_gamepiece = get_gamepiece(self)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.GAMEPIECE_DESTROYED):
				_on_gamepiece_removed(event as GamepieceEvents.DestroyedEvent)
	)

	# TODO: add all gamepieces already in the area
	# get_overlapping_areas() seems to not be working as expected


func _on_area_entered(area: Area2D):
	var gamepiece: Gamepiece = get_gamepiece(area)
	if gamepiece and gamepiece != parent_gamepiece:
		_add_gamepiece(gamepiece)


func _on_area_exited(area: Area2D):
	var gamepiece: Gamepiece = get_gamepiece(area)
	if gamepiece:
		_remove_gamepiece(gamepiece)


func _on_gamepiece_removed(event: GamepieceEvents.DestroyedEvent):
	_remove_gamepiece(event.gamepiece)


func _add_gamepiece(gamepiece: Gamepiece):
	for child in gamepiece.get_children():
		if child is NpcController:
			seen_npcs[gamepiece] = child
		elif child is ItemController:
			seen_items[gamepiece] = child


func _remove_gamepiece(gamepiece: Gamepiece):
	if seen_npcs.has(gamepiece):
		seen_npcs.erase(gamepiece)
	elif seen_items.has(gamepiece):
		seen_items.erase(gamepiece)


func get_gamepiece(area: Area2D) -> Gamepiece:
	if area.owner is Gamepiece:
		return area.owner as Gamepiece
	return null


func _sort_controllers_by_distance(controllers: Array) -> void:
	controllers.sort_custom(
		func(a: GamepieceController, b: GamepieceController):
			var a_dist = parent_gamepiece.cell.distance_to(a._gamepiece.cell)
			var b_dist = parent_gamepiece.cell.distance_to(b._gamepiece.cell)
			return b_dist > a_dist
	)


func get_items_by_distance() -> Array[ItemController]:
	var item_controllers := seen_items.values()
	_sort_controllers_by_distance(item_controllers)
	return item_controllers
