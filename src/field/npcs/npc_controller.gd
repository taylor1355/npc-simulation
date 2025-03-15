class_name NpcController extends GamepieceController

const GROUP_NAME: = "_NPC_CONTROLLER_GROUP"

# Backend NPC state
var npc_id: String
var npc_client: MockNpcClient
var event_log: Array[NpcEvent] = []
var last_processed_event_index: int = -1

var is_active: = false:
	set(value):
		is_active = value
		
		# set_process(is_active)
		# set_physics_process(is_active)
		set_process_input(is_active)
		set_process_unhandled_input(is_active)

var decision_timer: float = 0.0 # Time since last decision
const DECISION_INTERVAL: float = 3.0  # Make decisions every DECISION_INTERVAL seconds

# needs
# TODO: eventually refactor each need to be an object so each need can have an update fn, its own decay rate, etc.
# The list of valid need IDs should be stored as an enum in a globally accessible file
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
var is_wandering: bool = false

var current_interaction: Interaction = null
var current_request: InteractionRequest = null

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
		
		npc_client = Globals.npc_client
		npc_client.error.connect(_on_npc_error)
		
		# Listen for NPC client events
		FieldEvents.event_dispatched.connect(
			func(event: Event):
				match event.event_type:
					Event.Type.NPC_CREATED:
						_on_npc_created(event as NpcClientEvents.CreatedEvent)
					Event.Type.NPC_REMOVED:
						_on_npc_removed(event as NpcClientEvents.RemovedEvent)
					Event.Type.NPC_ACTION_CHOSEN:
						_on_action_chosen(event as NpcClientEvents.ActionChosenEvent)
					Event.Type.FOCUSED_GAMEPIECE_CHANGED:
						_on_focused_gamepiece_changed(
							(event as GamepieceEvents.FocusedEvent).gamepiece
						)
		)
		
		# Forward local signals
		need_changed.connect(
			func(need_id: String, new_value: float): 
				var event = NpcEvents.create_need_changed(_gamepiece, need_id, new_value)
				FieldEvents.dispatch(event)
		)

		for need_id in NEED_IDS:
			needs[need_id] = MAX_NEED_VALUE
			need_changed.emit(need_id, needs[need_id])
		decay_rate = randf_range(1, 2)
		
		# Wait a frame for the gameboard and physics engine to be fully setup. Once the physics 
		# engine is ready, its state may be queried to setup the pathfinder.
		await get_tree().process_frame
		
		# Set up NPC ID and initial state
		npc_id = str(get_instance_id()) # Use instance ID as unique identifier
		_gamepiece.display_name = "NPC" # Default name
		
		# Create NPC in backend
		npc_client.create_npc(
			npc_id,
			["curious", "active"], # Default traits
			"I am a new NPC in this world." # Initial memory
		)
		
		# If we're the focused gamepiece, request info after creation
		if _gamepiece == Globals.focused_gamepiece:
			npc_client.get_npc_info(npc_id)
		
		# Start behavior after a frame to ensure everything is set up
		await get_tree().process_frame
		decide_behavior()


func _exit_tree() -> void:
	if npc_id:
		npc_client.cleanup_npc(npc_id)

func _process(delta: float) -> void:
	# Update needs
	for need_id in NEED_IDS:
		update_need(need_id, -decay_rate * delta)
	
	# Regularly make decisions
	decision_timer += delta
	if decision_timer >= DECISION_INTERVAL:
		decide_behavior()

func set_is_paused(paused: bool) -> void:
	super.set_is_paused(paused)
	# set_process(!paused)
	# set_physics_process(!paused)
	

#############
### Needs ###
#############
func update_need(need_id: String, delta: float) -> void:
	if not needs.has(need_id):
		print("need_id not found: ", need_id)
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

	var event = GamepieceEvents.create_path_set(_gamepiece, destination)
	FieldEvents.dispatch.call_deferred(event)
	travel_to_cell(destination, true)


func set_movement_locked(locked: bool) -> void:
	var lock_status_changed = locked != movement_locked
	movement_locked = locked
	if not locked and lock_status_changed:
		decide_behavior()


######################
### Placeholder AI ###
######################
func decide_behavior() -> void:
	if not npc_id:
		return
	
	decision_timer = 0.0
	
	# Get visible items and prepare data for backend
	var seen_items = _vision_manager.get_items_by_distance()
	var item_data = []
	
	for item in seen_items:
		# Transform interactions to include metadata
		var processed_interactions = {}
		for interaction_name in item.interactions:
			var interaction = item.interactions[interaction_name]
			processed_interactions[interaction_name] = {
				"name": interaction.name,
				"description": interaction.description,
				"needs_filled": interaction.needs_filled,
				"needs_drained": interaction.needs_drained
			}
		
		item_data.append({
			"name": item.name,
			"cell": item._gamepiece.cell,
			"distance_to_npc": _gamepiece.cell.distance_to(item._gamepiece.cell),
			"interactions": processed_interactions,
			"current_interaction": item.current_interaction
		})
	
	# Add observation event
	event_log.append(NpcEvent.create_observation_event(
		_gamepiece.cell,
		item_data,
		needs,
		movement_locked,
		current_interaction,
		current_request
	))
	
	# Get unprocessed events
	var unprocessed_events = event_log.slice(last_processed_event_index + 1)
	
	# Get next action from backend
	npc_client.process_observation(npc_id, unprocessed_events)
	
	# Mark events as processed
	last_processed_event_index = event_log.size() - 1


# NPC Client handlers
func _on_npc_created(event: NpcClientEvents.CreatedEvent) -> void:
	if event.npc_id == npc_id and _gamepiece == Globals.focused_gamepiece:
		npc_client.get_npc_info(npc_id)

func _on_npc_removed(event: NpcClientEvents.RemovedEvent) -> void:
	if event.npc_id == npc_id:
		npc_id = ""

func _on_action_chosen(event: NpcClientEvents.ActionChosenEvent) -> void:
	if event.npc_id != npc_id:
		return
		
	var action_name = event.action_name
	var parameters = event.parameters
	
	match action_name:
		"move_to":
			if movement_locked:
				event_log.append(NpcEvent.create_error_event("Cannot move while movement is locked"))
			else:
				is_wandering = false
				set_new_destination(Vector2i(parameters.x, parameters.y))
		"interact_with":
			is_wandering = false
			var target_item = null
			var seen_items = _vision_manager.get_items_by_distance()
			for item in seen_items:
				if item.name == parameters.item_name:
					target_item = item
					break
					
			if target_item and target_item.interactions.has(parameters.interaction_name):
				var interaction = target_item.interactions[parameters.interaction_name]
				var request = interaction.create_start_request(self)
				request.item_controller = target_item
				current_request = request
				
				# Log the initial request
				event_log.append(NpcEvent.create_interaction_request_event(request))
				
				request.accepted.connect(
					func():
						current_interaction = interaction
						target_item.interaction_finished.connect(
							func(interaction_name, npc, payload): _on_interaction_finished(interaction_name, npc, payload),
							CONNECT_ONE_SHOT
						)
						
						# Log interaction started
						event_log.append(NpcEvent.create_interaction_update_event(
							request,
							NpcEvent.Type.INTERACTION_STARTED
						))
				)
				request.rejected.connect(
					func(reason: String):
						current_interaction = null
						
						# Log the rejected response with reason
						event_log.append(NpcEvent.create_interaction_rejected_event(request, reason))
						current_request = null
						decide_behavior()
				)
				target_item.request_interaction.call_deferred(request)
		"wander":
			if not is_wandering:
				is_wandering = true
				set_new_destination()
		"wait":
			is_wandering = false
		"continue":
			pass
		"cancel_interaction":
			is_wandering = false
			if current_interaction and current_request:
				var request = current_interaction.create_cancel_request(self)
				request.item_controller = current_request.item_controller
				
				# Log the cancel request
				event_log.append(NpcEvent.create_interaction_request_event(request))
				
				request.accepted.connect(
					func():
						# Log interaction canceled
						event_log.append(NpcEvent.create_interaction_update_event(
							request,
							NpcEvent.Type.INTERACTION_CANCELED
						))
						current_request = null
						current_interaction = null
				)
				
				request.rejected.connect(
					func(reason: String):
						# Log the rejected cancel with reason
						event_log.append(NpcEvent.create_interaction_rejected_event(request, reason))
				)
				
				current_interaction.cancel_request.emit(request)

func _on_npc_error(msg: String) -> void:
	print("NPC Error: ", msg)


################
### Handlers ###
################
func _on_interaction_finished(interaction_name: String, _npc: NpcController, payload: Dictionary) -> void:
	var item_name = payload.get("item_name", "")
	
	if current_request and current_interaction:
		# Log interaction finished event
		event_log.append(NpcEvent.create_interaction_update_event(
			current_request,
			NpcEvent.Type.INTERACTION_FINISHED
		))
		
		# Clear interaction state
		current_interaction = null
		current_request = null
		
		# Trigger next decision
		decide_behavior()
	
	
func _on_gamepiece_arrived() -> void:
	super._on_gamepiece_arrived()
	
	if is_wandering:
		set_new_destination()
	else:
		decide_behavior()


func _on_focused_gamepiece_changed(new_focused_gamepiece: Gamepiece) -> void:
	if new_focused_gamepiece == _gamepiece:
		reemit_needs()
		npc_client.get_npc_info(npc_id)
