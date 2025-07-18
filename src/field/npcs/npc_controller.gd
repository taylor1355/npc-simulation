class_name NpcController extends GamepieceController

const GROUP_NAME: = "_NPC_CONTROLLER_GROUP"

func get_entity_type() -> String:
	return "npc"

## Get formatted state information for UI display
func get_state_info_text(include_links: bool = false) -> String:
	if not state_machine or not state_machine.current_state:
		return ""
	
	var state = state_machine.current_state
	var state_name = state.state_name.capitalize()
	var emoji = state.get_state_emoji()
	var description = state.get_state_description(include_links)
	
	var text = "%s %s" % [emoji, state_name]
	if description:
		text += " - %s" % description
	
	return text

## Get UI-relevant information about this NPC's current state.
## Extends the base class implementation with NPC-specific state data.
func get_ui_info() -> Dictionary:
	var info = super.get_ui_info()
	
	# Add state information if available
	if state_machine:
		var state_info = state_machine.get_state_info()
		info[Globals.UIInfoFields.STATE_NAME] = state_info.get("state_name", "")
		info[Globals.UIInfoFields.STATE_ENUM] = state_info.get("state_enum", "")
		
		# Extract interaction name from context data if present
		var context_data = state_info.get("context_data", {})
		if context_data.has("interaction_name"):
			info[Globals.UIInfoFields.INTERACTION_NAME] = context_data["interaction_name"]
	
	return info

# Backend NPC state
var npc_id: String:
	get:
		return _gamepiece.entity_id if _gamepiece else ""
	set(value):
		push_warning("npc_id is deprecated, use entity_id from gamepiece")
var npc_client: NpcClientBase
var event_log: Array[NpcEvent] = []
var last_processed_event_index: int = -1
var is_switching_backend: bool = false

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

## Override from GamepieceController
func get_current_interaction() -> Interaction:
	return current_interaction
var current_request: InteractionBid = null
var pending_incoming_bids: Array[InteractionBid] = []

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
		
		# Forward state changes to EventBus
		state_machine.state_changed.connect(
			func(old_state_name: String, new_state_name: String):
				if _gamepiece and state_machine.current_state:
					var event = NpcEvents.create_state_changed(
						_gamepiece,
						old_state_name,
						new_state_name,
						state_machine.current_state
					)
					EventBus.dispatch(event)
		)
		
		# Listen for NPC client events
		EventBus.event_dispatched.connect(
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
					Event.Type.BACKEND_SWITCHED:
						_on_backend_switched(event as SystemEvents.BackendSwitchedEvent)
		)
		
		# Initialize needs manager
		var decay_rate = randf_range(1, 2)
		needs_manager = NeedsManager.new(decay_rate)
		
		# Forward needs manager signals to field events
		needs_manager.need_changed.connect(
			func(need_name: String, new_value: float): 
				need_changed.emit(need_name, new_value)
				var event = NpcEvents.create_need_changed(_gamepiece, need_name, new_value)
				EventBus.dispatch(event)
		)
		
		# Wait a frame for the gameboard and physics engine to be fully setup. Once the physics 
		# engine is ready, its state may be queried to setup the pathfinder.
		await get_tree().process_frame
		
		# Set up NPC ID and initial state
		npc_id = str(get_instance_id()) # Use instance ID as unique identifier
		# Only set default name if no display name is already set
		if _gamepiece.display_name.is_empty():
			_gamepiece.display_name = "NPC"
		
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
		
		# Initialize components after everything else is set up
		_initialize_components()
		
		decide_behavior()


func _exit_tree() -> void:
	if npc_id:
		npc_client.cleanup_npc(npc_id)

func _process(delta: float) -> void:
	# Update needs
	needs_manager.process_decay(delta)
	
	# Update MultiPartyBid timeout if we have a pending request
	if current_request and current_request is MultiPartyBid:
		var multi_bid = current_request as MultiPartyBid
		multi_bid.update_timeout(delta)
	
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
	EventBus.dispatch.call_deferred(event)
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
	# print("[NPC %s] State changed from %s to %s" % [npc_id, old_state_name, new_state_name])
	pass


#######################
### Decision-making ###
#######################
func decide_behavior() -> void:
	if not npc_id:
		return
	
	decision_timer = 0.0
	
	# Get visible items and prepare data for backend
	var seen_items := _vision_manager.get_items_by_distance()
	var item_data: Array[Dictionary] = []
	
	for item in seen_items:
		var interaction_dicts = item.get_available_interactions()
		var item_entry = {
			"name": item.get_display_name(),
			"cell": item._gamepiece.cell,
			"distance_to_npc": _gamepiece.cell.distance_to(item._gamepiece.cell),
			"interactions": interaction_dicts,
			"current_interaction": item.current_interaction
		}
		item_data.append(item_entry)
	
	# Get visible NPCs and prepare data for backend
	var seen_npcs := _vision_manager.get_npcs_by_distance()
	var npc_data: Array[Dictionary] = []
	for npc in seen_npcs:
		var npc_interaction_dicts = npc.get_available_interactions()
		
		npc_data.append({
			"npc_id": npc.npc_id,
			"name": npc.get_display_name(),
			"cell": npc._gamepiece.cell,
			"distance_to_npc": _gamepiece.cell.distance_to(npc._gamepiece.cell),
			"interactions": npc_interaction_dicts,
			"current_interaction": npc.current_interaction
		})
	
	# Add observation event
	event_log.append(NpcEvent.create_observation_event(
		_gamepiece.cell,
		item_data,
		needs_manager.get_all_needs(),
		movement_locked,
		current_interaction,
		current_request,
		state_machine.get_state_info(),
		npc_data
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
	# Don't clear NPC ID if we're in the middle of switching backends
	if not is_switching_backend and event.npc_id == npc_id:
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
	
	# Handle bid responses at controller level
	if action_name == "respond_to_interaction_bid":
		_handle_bid_response(parameters)
		return
	
	# Delegate to state machine
	state_machine.handle_action(action_name, parameters)

func _on_backend_switched(event: SystemEvents.BackendSwitchedEvent) -> void:
	print("[NPC %s] Backend switching to %s" % [npc_id, NpcClientFactory.get_backend_name(event.backend_type)])
	
	# Set flag to prevent NPC ID from being cleared during cleanup
	is_switching_backend = true
	
	# Disconnect from old client
	if npc_client and npc_client.error.is_connected(_on_npc_error):
		npc_client.error.disconnect(_on_npc_error)
	
	# Remove the NPC from the old backend
	if npc_client and npc_id:
		npc_client.cleanup_npc(npc_id)
	
	# Get the new client from factory
	npc_client = NpcClientFactory.get_shared_client()
	
	# Update the global reference
	Globals.npc_client = npc_client
	
	# Ensure the new client is in the scene tree
	if not npc_client.is_inside_tree():
		# The client needs to be in the tree to function properly
		# Find a suitable parent - ideally the same parent as the old client
		var parent = get_parent()
		while parent and parent.name != "Field":
			parent = parent.get_parent()
		
		if parent:
			parent.add_child(npc_client)
		else:
			# Fallback: add to the tree root
			get_tree().root.add_child(npc_client)
	
	npc_client.error.connect(_on_npc_error)
	
	# Re-create the NPC in the new backend
	if npc_id and _gamepiece:
		npc_client.create_npc(
			npc_id,
			["curious", "active"], # Default traits - same as initial creation
			"I am a new NPC in this world." # Initial memory
		)
	
	# Clear the flag now that switching is complete
	is_switching_backend = false


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
		if item.get_display_name() == item_name:
			return item
	return null

func _on_focused_gamepiece_changed(new_focused_gamepiece: Gamepiece) -> void:
	if new_focused_gamepiece == _gamepiece:
		needs_manager.reemit_all_needs()
		npc_client.get_npc_info(npc_id)


################
### Components ###
################
func add_component_node(component: GamepieceComponent) -> void:
	super.add_component_node(component)
	
	# Handle NPC-specific component setup
	# Note: interaction factories are now collected in the base GamepieceController class

func _initialize_components() -> void:
	# Find all NPC components that are children
	for child in get_children():
		if child is NpcComponent or child is EntityComponent:
			add_component_node(child)

func _on_component_interaction_finished(interaction_name: String, payload: Dictionary) -> void:
	# Handle component interaction completion
	print("[NPC %s] Component interaction '%s' finished" % [npc_id, interaction_name])
	
	# Clear interaction state if this was the current interaction
	if current_interaction and current_interaction.name == interaction_name:
		current_interaction = null


## Handle incoming interaction bids (so NPCs can be conversation targets)
func handle_interaction_bid(request: InteractionBid) -> void:
	# For now, NPCs can only handle multi-party bids (conversations)
	# Single-party interactions with NPCs could be added later
	if request is MultiPartyBid:
		# Store bid for async processing
		pending_incoming_bids.append(request)
		
		# Send to backend for decision-making
		var bid_event = NpcEvent.create_interaction_bid_received_event(request)
		event_log.append(bid_event)
	else:
		request.reject("NPCs currently only support multi-party interactions")

## Handle bid response action from backend
func _handle_bid_response(parameters: Dictionary) -> void:
	var bid_id = parameters.get("bid_id", "")
	var accept = parameters.get("accept", false)
	var reason = parameters.get("reason", "")
	
	# Find the bid by ID
	var bid: InteractionBid = null
	
	for pending_bid in pending_incoming_bids:
		if pending_bid.bid_id == bid_id:
			bid = pending_bid
			break
	
	if not bid:
		push_warning("[NPC %s] Could not find bid with ID %s" % [npc_id, bid_id])
		return
	
	# Remove from pending list
	pending_incoming_bids.erase(bid)
	
	# Respond to the bid
	if accept:
		if bid is MultiPartyBid:
			bid.add_participant_response(self, true)
		else:
			bid.accept()
	else:
		if bid is MultiPartyBid:
			bid.add_participant_response(self, false, reason)
		else:
			bid.reject(reason)

## Find an NPC by name or ID from visible NPCs
func _find_npc_by_name(npc_name: String) -> NpcController:
	var seen_npcs = _vision_manager.get_npcs_by_distance()
	for npc in seen_npcs:
		if npc.get_display_name() == npc_name or npc.npc_id == npc_name:
			return npc
	return null

## Handle interaction transition request from MultiPartyBid coordination
func request_interaction_transition(participant: NpcController, interaction: Interaction) -> void:
	# Only process if this signal is for our controller
	if participant != self:
		return
		
	# Controller decides how to handle transition based on current state
	if current_interaction:
		# End current interaction first
		current_interaction._on_end({})
		current_interaction = null
		current_request = null
	
	# Set up new interaction
	current_interaction = interaction
	var context = interaction.create_context()
	if not context:
		push_error("[NPC %s] Failed to create context for interaction" % npc_id)
		return
	
	# Register with InteractionRegistry (for multi-party interactions)
	InteractionRegistry.register_interaction(interaction, context)
	
	var interacting_state = ControllerInteractingState.new(self, interaction, context)
	state_machine.change_state(interacting_state)
