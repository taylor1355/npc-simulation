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
var movement_locked: bool = false

# State machine
enum NPCState {
	IDLE,
	MOVING_TO_ITEM,
	INTERACTING,
	WANDERING
}

var current_state: NPCState = NPCState.IDLE
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
		
	var old_value = needs[need_id]
	needs[need_id] += delta
	needs[need_id] = clamp(needs[need_id], 0, MAX_NEED_VALUE)
	need_changed.emit(need_id, needs[need_id])
	
	# Trigger behavior update at energy thresholds
	if need_id == "energy":
		if (old_value < MAX_NEED_VALUE and needs[need_id] >= MAX_NEED_VALUE) or \
		   (old_value > 0 and needs[need_id] <= 0):
			print("[NpcController] Energy threshold reached, deciding behavior")
			decide_behavior()


func reemit_needs() -> void:
	for need_id in NEED_IDS:
		need_changed.emit(need_id, needs[need_id])


###################
### Pathfinding ###
###################
func set_new_destination(new_destination = null) -> void:
	if movement_locked:
		return

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


func set_movement_locked(locked: bool) -> void:
	print("[NpcController] Setting movement_locked to ", locked)
	movement_locked = locked


######################
### Placeholder AI ###
######################
func decide_behavior() -> void:
	print("\n[NpcController] Deciding behavior")
	print("[NpcController] Current state: ", current_state)
	print("[NpcController] Movement locked: ", movement_locked)
	print("[NpcController] Current interaction: ", current_interaction.name if current_interaction else "none")
	print("[NpcController] Energy level: ", needs["energy"], "/", MAX_NEED_VALUE)
	
	# If movement is locked, we can only be in INTERACTING state
	if movement_locked and current_state != NPCState.INTERACTING:
		print("[NpcController] Movement locked, forcing IDLE state")
		current_state = NPCState.IDLE
		return
		
	# If currently interacting, check if we should stop
	if current_interaction:
		current_state = NPCState.INTERACTING
		# Stop sitting if energy is full
		if current_interaction.name == "sit" and needs["energy"] >= MAX_NEED_VALUE:
			print("[NpcController] Energy full, stopping sit interaction")
			var cancel_request = current_interaction.create_cancel_request(self)
			current_interaction.cancel_request.emit(cancel_request)
		return

	var seen_items: Array = _vision_manager.get_items_by_distance()
	if seen_items.is_empty():
		print("[NpcController] No items visible, wandering")
		current_state = NPCState.WANDERING
		set_new_destination()
		return
		
	var closest_item = seen_items[0]
	var closest_distance = _gamepiece.cell.distance_to(closest_item._gamepiece.cell)
	print("[NpcController] Closest item at distance: ", closest_distance)
	
	# If next to an item with interactions, interact with it
	if closest_distance <= 1 and closest_item.interactions:
		# Always check for sit interaction first when energy is not full
		var interaction = null
		if needs["energy"] < 0.5 * MAX_NEED_VALUE and closest_item.interactions.has("sit"):
			print("[NpcController] Energy not full, choosing sit interaction")
			interaction = closest_item.interactions["sit"]
		else:
			print("[NpcController] Energy full or no sit interaction available")
			interaction = closest_item.interactions.values()[0]
			
		var interaction_request = interaction.create_start_request(self)
		interaction_request.accepted.connect(
			func():
				current_interaction = interaction
				closest_item.interaction_finished.connect(_on_interaction_finished)
				current_state = NPCState.INTERACTING
		)
		interaction_request.rejected.connect(
			func(_reason):
				current_interaction = null
				current_state = NPCState.WANDERING
				set_new_destination()
		)
		closest_item.request_interaction.call_deferred(interaction_request)
	# Otherwise move to closest available item
	else:
		for item in seen_items:
			if not item.current_interaction:
				current_state = NPCState.MOVING_TO_ITEM
				set_new_destination(item._gamepiece.cell)
				return
		
		current_state = NPCState.WANDERING
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
