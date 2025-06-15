## Base controller responsible for the pathfinding state and movement of a gamepiece.
##
## A controller is responsible for all gamepiece behaviour, especially movement. The base controller
## provides several utility methods that query the [Gameboard]/[Gamepiece] state. 
##
## Specific controllers will usually be subclassed from this base class. See [ItemController] for a
## detailed example.
##
## [br][br]Requires a gamepiece as parent. The controller is derived from Node2D to account for
## [member global_scale] when searching for paths/objects.
@icon("res://assets/editor/icons/IconGamepieceController.svg")
class_name GamepieceController extends Node2D

# Colliding objects that have the following property set to true will block movement.
const BLOCKING_PROPERTY: = "blocks_movement"

## Colliders matching the following mask will be used to determine which cells are walkable. Cells
## containing any terrain collider will not be included for pathfinding.
@export_flags_2d_physics var terrain_mask: = 0x2

## The physics layers which will be used to search for gamepiece-related objects.
## Please see the project properties for the specific physics layers. [b]All[/b] collision shapes
## matching the mask will be checked regardless of position in the scene tree.
@export_flags_2d_physics var gamepiece_mask: = 0x1

## A pathfinder will be built from and respond to the physics state. This will be used to determine
## movement for the parent [Gamepiece].
var pathfinder: Pathfinder

## The type of entity this controller manages. Override in subclasses.
func get_entity_type() -> String:
	return "gamepiece"

## Get the current cell position of the gamepiece.
func get_cell_position() -> Vector2i:
	return _gamepiece.cell if _gamepiece else Vector2i.ZERO

## Get the display name of the gamepiece.
func get_display_name() -> String:
	return _gamepiece.display_name if _gamepiece else ""

# Keep track of cells that need an update and do so as a batch before the next path search.
var _cells_to_update: PackedVector2Array = []

# The controller operates on its direct parent, which must be a gamepiece object.
var _gamepiece: Gamepiece

# Refer to _gamepiece's gameboard object to prevent repeatedly typing '_gamepiece.gameboard'.
var _gameboard: Gameboard

# Create two internal collision finders that will search for other objects using Godot's built-in
# physics engine.
var _gamepiece_searcher: CollisionFinder
var _terrain_searcher: CollisionFinder

# Controllers are paused on a few conditions:
# a) The gamestate changes to something other than the field, where controllers should not run.
# b) A cutscene is run, pausing most input.
var is_paused: = false:
	set = set_is_paused

# Keep track of a move path. The controller will check that the path is clear each time the 
# gamepiece needs to continue on to the next cell.
var _waypoints: Array[Vector2i] = []
var _current_waypoint: Vector2i

var components: Array[GamepieceComponent] = []

## Collection of interaction factories from EntityComponents
var interaction_factories: Dictionary[String, InteractionFactory] = {}

func get_component(type: GDScript) -> GamepieceComponent:
	for component in components:
		if component.get_script() == type:
			return component
	return null

func has_component(type: GDScript) -> bool:
	return get_component(type) != null

func add_component_node(component: GamepieceComponent) -> void:
	if not components.has(component):
		components.append(component)
	if not component.is_inside_tree():
		add_child(component)
	
	# Only collect interaction factories at runtime
	# CRITICAL: This was causing 30+ second editor freezes
	if Engine.is_editor_hint():
		return
		
	# Collect interaction factories from EntityComponent
	if component is EntityComponent:
		component.interaction_finished.connect(_on_component_interaction_finished)
		
		# Collect interaction factories from component
		for factory in component.get_interaction_factories():
			var factory_name = factory.get_interaction_name()
			if interaction_factories.has(factory_name):
				push_error("Duplicate interaction factory found: %s in component: %s" % [factory_name, component.get_component_name()])
			else:
				interaction_factories[factory_name] = factory

func _ready() -> void:
	if not Engine.is_editor_hint():
		# A controller must operate on a gamepiece. Obtain the gamepiece reference and pull 
		# necessary information from it.
		_gamepiece = get_parent() as Gamepiece
		assert(_gamepiece, "The GamepieceController must have a Gamepiece as a parent. "
			+ "%s is not a gamepiece!" % get_parent().name)
			
		# Collect all components
		for child in get_children():
			if child is GamepieceComponent:
				add_component_node(child)
		
		_gameboard = _gamepiece.gameboard
		assert(_gameboard, "%s error: invalid Gameboard object!" % name)
		
		EventBus.input_paused.connect(_on_input_paused)
		
		_gamepiece.arriving.connect(_on_gamepiece_arriving)
		_gamepiece.arrived.connect(_on_gamepiece_arrived)
		
		# The controller will be notified of any changes in the gameboard and respond accordingly.
		EventBus.event_dispatched.connect(
			func(event: Event):
				if event.is_type(Event.Type.GAMEPIECE_CELL_CHANGED):
					_on_gamepiece_cell_changed(event as GamepieceEvents.CellChangedEvent)
		)
		EventBus.terrain_changed.connect(_on_terrain_passability_changed)
		
		# Update pathfinding when movement blocking changes
		for gamepiece in get_tree().get_nodes_in_group("_GAMEPIECE_GROUP"):
			gamepiece.blocks_movement_changed.connect(_on_blocks_movement_changed)
		
		# Create the objects that will be used to query the state of the gamepieces and terrain.
		var min_cell_axis: = minf(_gameboard.cell_size.x-1, _gameboard.cell_size.y-1) / 2.0
		_gamepiece_searcher = CollisionFinder.new(get_world_2d().direct_space_state, min_cell_axis,
			gamepiece_mask)
		_terrain_searcher = CollisionFinder.new(get_world_2d().direct_space_state, min_cell_axis,
			terrain_mask)
		
		# Wait a frame for the gameboard and physics engine to be fully setup. Once the physics 
		# engine is ready, its state may be queried to setup the pathfinder.
		await get_tree().process_frame
		_rebuild_pathfinder()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not get_parent() is Gamepiece:
		warnings.append("Expects a Gamepiece as parent to correctly function. "
			+ "Please only use GamepieceController as a child of a Gamepiece for correct animation.")
	
	return warnings

func travel_to_cell(destination: Vector2i, allow_adjacent_cells: = false) -> void:
	_update_changed_cells()
	_waypoints = pathfinder.get_path_cells(_gamepiece.cell, destination)

	# No path could be found to the destination. If allowed, search for a path to an adjacent cell.
	if _waypoints.size() <= 1 and allow_adjacent_cells:
		_waypoints = pathfinder.get_path_cells_to_adjacent_cell(_gamepiece.cell, destination)
	
	# Only follow a valid path with a length greater than 0 (more than one waypoint).
	if _waypoints.size() > 1:
		# The first waypoint is the focus' current cell and may be discarded.
		_waypoints.remove_at(0)
		_current_waypoint = _waypoints.pop_front()
		
		_gamepiece.travel_to_cell(_current_waypoint)
	
	else:
		_waypoints.clear()

## Returns true if a given cell is occupied by something that has a collider matching 
## [member gamepiece_mask].
func is_cell_blocked(cell: Vector2i) -> bool:
	var search_coordinates: = Vector2(_gameboard.cell_to_pixel(cell)) * global_scale
	var collisions = _gamepiece_searcher.search(search_coordinates)
	
	# Take advantage of duck typing: any colliding object could block movement. Look at the owner
	# of the collision shape for a blocking flag.
	# Please see BLOCKING_PROPERTY for more information.
	# Note that not all collisions will have this blocking flag. In those cases, assume that the
	# collision is a blocking collision.
	for collision in collisions:
		var blocks_movement = true
		if collision.collider.owner.get(BLOCKING_PROPERTY) != null:
			blocks_movement = collision.collider.owner.get(BLOCKING_PROPERTY) as bool
		
		if blocks_movement:
			return true
	
	# There is one last check to make. It is possible that a gamepiece has decided to move to cell 
	# THIS frame. It's collision shape will not move until next frame, so the events manager may
	# have flagged this cell as 'targeted this frame'.
	return EventBus.did_gp_move_to_cell_this_frame(cell)

## Find all collision matching [member gamepiece_mask] at a given cell.
func get_collisions(cell: Vector2i) -> Array[Dictionary]:
	var search_coordinates: = Vector2(_gameboard.cell_to_pixel(cell)) * global_scale
	return _gamepiece_searcher.search(search_coordinates)

func set_is_paused(paused: bool) -> void:
	is_paused = paused
		
	if is_inside_tree() and not _waypoints.is_empty():
		_current_waypoint = _waypoints.pop_front()
		_gamepiece.travel_to_cell(_current_waypoint)

# Completely rebuild the pathfinder, searching for all empty terrain within the gameboard 
# boundaries.
# Empty terrain is considered a cell that is NOT occupied by a collider with a terrain_mask.
func _rebuild_pathfinder() -> void:
	var pathable_cells: Array[Vector2i] = []
	
	# Loop through ALL cells within the board boundaries. The only cells that will not be considered
	# walkable are those that contain a collision shape matching the terrain layer mask.
	for x in range(_gameboard.boundaries.position.x, _gameboard.boundaries.end.x):
		for y in range(_gameboard.boundaries.position.y, _gameboard.boundaries.end.y):
			var cell: = Vector2i(x, y)
			
			# To find collision shapes we'll query a PhysicsDirectSpaceState2D (usually that of the
			# current viewport's World2D). If there is a collision shape matching terrainn_mask
			# then we'll know to discard the cell. Otherwise it may be considered walkable.
			var search_coordinates: = Vector2(_gameboard.cell_to_pixel(cell)) * global_scale
			var collisions: = _terrain_searcher.search(search_coordinates)
			if collisions.is_empty():
				pathable_cells.append(cell)
	
	pathfinder = Pathfinder.new(pathable_cells, _gameboard)
	_find_all_blocked_cells()

# The following method searches ALL cells contained in the pathfinder for objects that might block
# gamepiece movement. 
# 
# This method may be overwritten depending on the movement behaviour of a controller's focus. For
# instance, a teleporting or flying focus will not be blocked by grounded gamepieces.
func _find_all_blocked_cells() -> void:
	var blocked_cells: Array[Vector2i] = []
	
	for cell in pathfinder.get_cells():
		if is_cell_blocked(cell):
			blocked_cells.append(cell)
	
	pathfinder.set_blocked_cells(blocked_cells)

# Go through all cells that have been flagged for updates and determine if they are indeed occupied.
# This should usually be called before searching for a move path.
func _update_changed_cells() -> void:
	# Duplicate entries may be included in _cells_to_update. Filter them by converting the array to
	# dictionary keys (which are always unique).
	# This ensures that given coordinates are only queried once per update.
	var checked_coordinates: = {}
	
	for cell in _cells_to_update:
		if not cell in checked_coordinates:
			pathfinder.block_cell(cell, is_cell_blocked(cell))
			checked_coordinates[cell] = null
	
	_cells_to_update.clear()

func _on_input_paused(paused: bool) -> void:
	is_paused = paused

# The controller's focus will finish travelling this frame unless it is extended. When following a
# path, the gamepiece will want to travel to the next waypoint.
# excess_distance covers cases where the gamepiece will move past the current waypoint and prevents
# stuttering for a single frame (or slower-than-expected movement for *very* fast gamepieces).
func _on_gamepiece_arriving(excess_distance: float) -> void:
	# If the gamepiece is currently following a path, continue moving along the path if it is still
	# a valid movement path (since obstacles may shift while in transit).
	if not _waypoints.is_empty() and not is_paused:
		while not _waypoints.is_empty() and excess_distance > 0:
			if is_cell_blocked(_waypoints[0]) \
					or EventBus.did_gp_move_to_cell_this_frame(_waypoints[0]):
				return
			
			_current_waypoint = _waypoints.pop_front()
			var distance_to_waypoint: = \
				_gamepiece.position.distance_to(_gameboard.cell_to_pixel(_current_waypoint))
			
			_gamepiece.travel_to_cell(_current_waypoint)
			excess_distance -= distance_to_waypoint

func _on_gamepiece_arrived() -> void:
	_waypoints.clear()

# Whenever a gamepiece moves, flag its destination and origin as in need of an update.
func _on_gamepiece_cell_changed(event: GamepieceEvents.CellChangedEvent) -> void:
	_cells_to_update.append(event.old_cell)
	_cells_to_update.append(event.gamepiece.cell)

# Various events may trigger a change in the terrain which, in turn, changes which cells are
# passable. The pathfinder will need to be rebuilt.
func _on_terrain_passability_changed() -> void:
	_rebuild_pathfinder()

# When a gamepiece's blocks_movement changes, update pathfinding
func _on_blocks_movement_changed() -> void:
	_find_all_blocked_cells()

## Returns available interactions in a format compatible with the vision system
func get_available_interactions() -> Dictionary:
	# Don't create interactions in the editor
	if Engine.is_editor_hint():
		return {}
		
	# Return interaction data in same format as Interaction.to_dict() for vision system
	var available = {}
	
	for name in interaction_factories:
		var factory = interaction_factories[name]
		# Create temporary interaction to get its data
		# NOTE: This is marked as inefficient but maintains consistency
		var temp_interaction = factory.create_interaction({"requester": null, "target": self})
		if temp_interaction:
			available[name] = temp_interaction.to_dict()
	
	return available

## Called when a component's interaction finishes. Override in subclasses if needed.
func _on_component_interaction_finished(interaction_name: String, payload: Dictionary) -> void:
	# Override in subclasses if needed
	pass
