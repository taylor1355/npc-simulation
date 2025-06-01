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
var needs_manager: NeedsManager

# State machine
var state_machine: ControllerStateMachine
var movement_locked: bool = false

# Current state data
var destination: Vector2i
var current_interaction: Interaction = null
var current_request: InteractionBid = null

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
		
		# Initialize state machine
		state_machine = ControllerStateMachine.new(self)
		state_machine.state_changed.connect(_on_state_changed)
		
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
		
		# Initialize needs manager
		var decay_rate = randf_range(1, 2)
		needs_manager = NeedsManager.new(decay_rate)
		
		# Forward needs manager signals to field events
		needs_manager.need_changed.connect(
			func(need_name: String, new_value: float): 
				need_changed.emit(need_name, new_value)
				var event = NpcEvents.create_need_changed(_gamepiece, need_name, new_value)
				FieldEvents.dispatch(event)
		)
		
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
	needs_manager.process_decay(delta)
	
	# Regularly make decisions
	decision_timer += delta
	if decision_timer >= DECISION_INTERVAL:
		decide_behavior()

func set_is_paused(paused: bool) -> void:
	super.set_is_paused(paused)
	# set_process(!paused)
	# set_physics_process(!paused)


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


#######################
### State Management ###
#######################
func change_state(new_state: BaseControllerState) -> void:
	state_machine.change_state(new_state)

func _on_state_changed(old_state_name: String, new_state_name: String) -> void:
	# Log state transition
	print("[NPC %s] State changed from %s to %s" % [npc_id, old_state_name, new_state_name])


######################
### Placeholder AI ###
######################
func decide_behavior() -> void:
	if not npc_id:
		return
	
	decision_timer = 0.0
	
	# Get visible items and prepare data for backend
	var seen_items := _vision_manager.get_items_by_distance()
	var item_data: Array[Dictionary] = []
	for item in seen_items:
		var interaction_dicts = {}
		for interaction_name in item.interactions:
			var interaction = item.interactions[interaction_name]
			interaction_dicts[interaction_name] = interaction.to_dict()
		
		item_data.append({
			"name": item.name,
			"cell": item._gamepiece.cell,
			"distance_to_npc": _gamepiece.cell.distance_to(item._gamepiece.cell),
			"interactions": interaction_dicts,
			"current_interaction": item.current_interaction
		})
	
	# Add observation event
	event_log.append(NpcEvent.create_observation_event(
		_gamepiece.cell,
		item_data,
		needs_manager.get_all_needs(),
		movement_locked,
		current_interaction,
		current_request,
		state_machine.get_state_info()
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
	
	# Log the action attempt
	print("[NPC %s] Action '%s' in state %s" % [
		npc_id, 
		action_name, 
		state_machine.get_state_info().state_enum
	])
	
	# Delegate to state machine
	state_machine.handle_action(action_name, parameters)


# Interaction callbacks that delegate to current state
func _on_interaction_accepted(request: InteractionBid) -> void:
	state_machine.current_state.on_interaction_accepted(request)

func _on_interaction_rejected(request: InteractionBid, reason: String) -> void:
	state_machine.current_state.on_interaction_rejected(request, reason)

func _on_interaction_finished(interaction_name: String, npc: NpcController, payload: Dictionary) -> void:
	state_machine.current_state.on_interaction_finished(interaction_name, npc, payload)

func _on_npc_error(msg: String) -> void:
	print("NPC Error: ", msg)

func _on_gamepiece_arrived() -> void:
	super._on_gamepiece_arrived()
	
	# Delegate to state machine
	state_machine.on_gamepiece_arrived()

# Helper to find item by name, used by states
func _find_item_by_name(item_name: String) -> ItemController:
	var seen_items = _vision_manager.get_items_by_distance()
	for item in seen_items:
		if item.name == item_name:
			return item
	return null

func _on_focused_gamepiece_changed(new_focused_gamepiece: Gamepiece) -> void:
	if new_focused_gamepiece == _gamepiece:
		needs_manager.reemit_all_needs()
		npc_client.get_npc_info(npc_id)
