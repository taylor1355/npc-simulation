class_name NpcController extends GamepieceController

const GROUP_NAME: = "_NPC_CONTROLLER_GROUP"

var is_active: = false:
	set(value):
		is_active = value
		
		# set_process(is_active)
		# set_physics_process(is_active)
		set_process_input(is_active)
		set_process_unhandled_input(is_active)

# needs
# TODO: eventually refactor each need to be an object so each need can have an update fn, its own decay rate, etc.
var decay_rate: float = 0.0 # for testing, just set to a random value between 1 and 5
var MAX_NEED_VALUE: = 100.0
var NEED_IDS = [
	"hunger",
	"hygiene",
	"fun",
	"energy",
]
var needs = {}

# pathfinding
var destination : Vector2i

# placeholder ai state
var behavior: String = "wander"
var current_interaction: Interaction = null

@onready var _vision_manager: VisionManager = $VisionArea as VisionManager

signal need_changed(need_id: String, new_value: float)


################
### Built-in ###
################
func _ready() -> void:
	super._ready()

	set_process(true)
	set_physics_process(false)

	if not Engine.is_editor_hint():
		add_to_group(GROUP_NAME)
		
		# Forward local signals to the corresponding FieldEvents
		need_changed.connect(
			func(need_id: String, new_value: float): FieldEvents.npc_need_changed.emit(_gamepiece, need_id, new_value)
		)

		for need_id in NEED_IDS:
			needs[need_id] = MAX_NEED_VALUE
			need_changed.emit(need_id, needs[need_id])
		decay_rate = randf_range(1, 5)
	
		# Wait a frame for the gameboard and physics engine to be fully setup. Once the physics 
		# engine is ready, its state may be queried to setup the pathfinder.
		await get_tree().process_frame
		decide_behavior.call_deferred()


func _process(delta: float) -> void:
	# TODO: accumulate delta and only update needs when it reaches a certain threshold
	for need_id in NEED_IDS:
		update_need(need_id, -decay_rate * delta)
	

func set_is_paused(paused: bool) -> void:
	super.set_is_paused(paused)
	# set_process(!paused)
	# set_physics_process(!paused)
	

#############
### Needs ###
#############
func update_need(need_id: String, delta: float) -> void:
	if not needs.has(need_id):
		print("NpcAi: need_id not found: ", need_id)
		return
	needs[need_id] += delta
	needs[need_id] = clamp(needs[need_id], 0, MAX_NEED_VALUE)
	need_changed.emit(need_id, needs[need_id])


func reemit_needs() -> void:
	for need_id in NEED_IDS:
		need_changed.emit(need_id, needs[need_id])


###################
### Pathfinding ###
###################
func set_new_destination(new_destination = null) -> void:
	if not new_destination:
		var bounds : Rect2i = _gamepiece.gameboard.boundaries
		destination = bounds.position + Vector2i(
			randi_range(0, bounds.size.x - 1),
			randi_range(0, bounds.size.y - 1),
		)
	else:
		destination = new_destination as Vector2i

	print("Set new destination (", destination, "). Blocked? ", is_cell_blocked(destination))

	FieldEvents.gamepiece_path_set.emit.call_deferred(_gamepiece, destination)
	travel_to_cell(destination, true)


######################
### Placeholder AI ###
######################
func decide_behavior() -> void:
	var seen_items: Array = _vision_manager.get_items_by_distance()
	var closest_item = seen_items[0] if seen_items else null
	var closest_distance = _gamepiece.cell.distance_to(closest_item._gamepiece.cell) if closest_item else null

	# if NPC is currently interacting with an item, wait to finish the interaction
	if current_interaction: 
		behavior = "interact"
	# if NPC is next to an item, interact with it
	elif closest_item and closest_distance <= 1:
		behavior = "pending_interaction"
		if closest_item.interactions:
			var interaction = closest_item.interactions.values()[0]
			var interaction_request = interaction.create_start_request(self)
			interaction_request.accepted.connect(
				func():
					current_interaction = interaction
					closest_item.interaction_finished.connect(_on_interaction_finished)
					decide_behavior()
			)
			interaction_request.rejected.connect(
				func(_reason):
					current_interaction = null
					behavior = "wander"
					set_new_destination()
			)
			closest_item.request_interaction.call_deferred(interaction_request)
	# if NPC is at least 2 squares away from any seen items, move to the closest one (or wander if no close items)
	else:
		for item in _vision_manager.get_items_by_distance():
			if not item.current_interaction:
				behavior = "move_to_item"
				set_new_destination(item._gamepiece.cell)
				return
		behavior = "wander"
		set_new_destination()


################
### Handlers ###
################
func _on_interaction_finished(_interaction_name: String, npc: NpcController, payload: Dictionary) -> void:
	if npc == self:
		current_interaction = null
	decide_behavior()
	
	
func _on_gamepiece_arrived() -> void:
	super._on_gamepiece_arrived()
	decide_behavior()


func _on_focused_gamepiece_changed(new_focused_gamepiece: Gamepiece) -> void:
	if new_focused_gamepiece == _gamepiece:
		reemit_needs()
