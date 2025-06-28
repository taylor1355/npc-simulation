class_name VisionManager extends Area2D

var _parent_gamepiece: Gamepiece = null  # Private cached value
var seen_npcs: Dictionary[Gamepiece, NpcController] = {}
var seen_items: Dictionary[Gamepiece, ItemController] = {}

## Lazy-loaded parent gamepiece property
var parent_gamepiece: Gamepiece:
	get:
		if not _parent_gamepiece:
			_parent_gamepiece = get_gamepiece(self)
			if not _parent_gamepiece:
				push_error("VisionManager failed to find parent gamepiece")
		return _parent_gamepiece


func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.GAMEPIECE_DESTROYED):
				_on_gamepiece_removed(event as GamepieceEvents.DestroyedEvent)
	)
	
	# Check for already overlapping areas after a frame to ensure metadata is set
	await get_tree().process_frame
	for area in get_overlapping_areas():
		if area != self:  # Don't process ourselves
			_on_area_entered(area)


func _on_area_entered(area: Area2D):
	var gamepiece: Gamepiece = get_gamepiece(area)
	
	if not gamepiece:
		return
		
	if gamepiece == parent_gamepiece:
		return
		
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
	# All collision areas should have gamepiece metadata set by Gamepiece._ready()
	if not area.has_meta(Globals.GAMEPIECE_META_KEY):
		push_error("CollisionArea %s missing gamepiece metadata" % area.get_path())
		return null
	
	return area.get_meta(Globals.GAMEPIECE_META_KEY) as Gamepiece


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

func get_npcs_by_distance() -> Array[NpcController]:
	var npc_controllers := seen_npcs.values()
	_sort_controllers_by_distance(npc_controllers)
	return npc_controllers
