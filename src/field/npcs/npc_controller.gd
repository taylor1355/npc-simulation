class_name NpcController extends GamepieceController

const GROUP_NAME: = "_NPC_CONTROLLER_GROUP"

# Backend NPC state
var npc_id: String
var npc_client: NpcClient

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

# Idle timing (seconds)
const MOVEMENT_COOLDOWN = 0.75  # How long to idle after movement is unlocked 
var idle_timer: float = 0.0  # Time left to idle

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
		decay_rate = randf_range(1, 5)
		
		# Create new NPC if no ID provided
		if not npc_id:
			npc_id = str(get_instance_id()) # Use instance ID as unique identifier
			npc_client.create_npc(
				npc_id,
				["curious", "active"], # Default traits
				"I am a new NPC in this world." # Initial memory
			)
	
		# Wait a frame for the gameboard and physics engine to be fully setup. Once the physics 
		# engine is ready, its state may be queried to setup the pathfinder.
		await get_tree().process_frame
		decide_behavior.call_deferred()


func _exit_tree() -> void:
	if npc_id:
		npc_client.cleanup_npc(npc_id)

func _process(delta: float) -> void:
	# Update needs
	for need_id in NEED_IDS:
		update_need(need_id, -decay_rate * delta)
	
	# Handle idle timer if we're idling
	if current_state == NPCState.IDLE and idle_timer > 0:
		idle_timer -= delta
		if idle_timer <= 0:
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
		
	var old_value = needs[need_id]
	needs[need_id] += delta
	needs[need_id] = clamp(needs[need_id], 0, MAX_NEED_VALUE)
	need_changed.emit(need_id, needs[need_id])
	
	# Trigger behavior update at energy thresholds
	if need_id == "energy":
		if (old_value < MAX_NEED_VALUE and needs[need_id] >= MAX_NEED_VALUE) or \
		   (old_value > 0 and needs[need_id] <= 0):
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

	var event = GamepieceEvents.create_path_set(_gamepiece, destination)
	FieldEvents.dispatch.call_deferred(event)
	travel_to_cell(destination, true)


func set_movement_locked(locked: bool) -> void:
	if movement_locked and not locked:
		current_state = NPCState.IDLE
		idle_timer = MOVEMENT_COOLDOWN
	movement_locked = locked


######################
### Placeholder AI ###
######################
func decide_behavior() -> void:
	# First check if we need to stop sitting, regardless of movement lock
	if current_interaction and current_interaction.name == "sit" and needs["energy"] >= MAX_NEED_VALUE:
		var cancel_request = current_interaction.create_cancel_request(self)
		current_interaction.cancel_request.emit(cancel_request)
		return
		
	# Then check movement lock and idle timer
	if movement_locked or (current_state == NPCState.IDLE and idle_timer > 0):
		return
		
	# If currently interacting, continue interaction
	if current_interaction:
		current_state = NPCState.INTERACTING
		return

	# Check visible items
	var seen_items: Array = _vision_manager.get_items_by_distance()
	
	# Build observation and available actions
	var observation = _build_observation(seen_items)
	var available_actions = _build_available_actions(seen_items)
	
	# Process observation through NPC client if we have an ID
	if npc_id:
		npc_client.process_observation(npc_id, observation, available_actions)
	else:
		# Fallback to default behavior if no NPC client connection
		_handle_default_behavior(seen_items)

func _build_observation(seen_items: Array) -> String:
	var observation = "You are in a room. "
	
	if seen_items.is_empty():
		observation += "You don't see any items nearby."
	else:
		observation += "You see: "
		for i in range(seen_items.size()):
			var item = seen_items[i]
			if i > 0:
				observation += ", " if i < seen_items.size() - 1 else " and "
			observation += "a " + item.name
			
			var distance = _gamepiece.cell.distance_to(item._gamepiece.cell)
			if distance <= 1:
				observation += " within reach"
			else:
				observation += " " + str(distance) + " steps away"
				
	observation += "\nYour current needs are: "
	for need_id in NEED_IDS:
		observation += need_id + " (" + str(needs[need_id]) + "%), "
		
	return observation

func _build_available_actions(seen_items: Array) -> Array[NpcClient.Action]:
	var actions: Array[NpcClient.Action] = []
	
	# Add movement actions for items not in range
	for item in seen_items:
		var distance = _gamepiece.cell.distance_to(item._gamepiece.cell)
		if distance > 1:
			actions.append(NpcClient.Action.new(
				"move_to",
				"Move to the " + item.name,
				{
					"x": item._gamepiece.cell.x,
					"y": item._gamepiece.cell.y
				}
			))
	
	# Add interaction actions for items in range
	for item in seen_items:
		var distance = _gamepiece.cell.distance_to(item._gamepiece.cell)
		if distance <= 1 and item.interactions and not item.current_interaction:
			for interaction_name in item.interactions:
				actions.append(NpcClient.Action.new(
					"interact",
					interaction_name + " with the " + item.name,
					{
						"item_name": item.name,
						"interaction_type": interaction_name
					}
				))
	
	# Add wandering as a fallback
	actions.append(NpcClient.Action.new(
		"wander",
		"Walk to a random location",
		{}
	))
	
	return actions

func _handle_default_behavior(seen_items: Array) -> void:
	if seen_items.is_empty():
		current_state = NPCState.WANDERING
		set_new_destination()
		return
	
	# Try to interact with each visible item
	for item in seen_items:
		if not item.interactions or item.current_interaction:
			continue

		# Skip chairs if energy is high
		if item.interactions.has("sit") and needs["energy"] >= 0.5 * MAX_NEED_VALUE:
			continue
			
		var distance = _gamepiece.cell.distance_to(item._gamepiece.cell)
		if distance > 1:
			current_state = NPCState.MOVING_TO_ITEM
			set_new_destination(item._gamepiece.cell)
			return
			
		# Choose interaction
		var interaction = null
		if needs["energy"] < 0.5 * MAX_NEED_VALUE and item.interactions.has("sit"):
			interaction = item.interactions["sit"]
		else:
			interaction = item.interactions.values()[0]
			
		# Request interaction
		var interaction_request = interaction.create_start_request(self)
		interaction_request.accepted.connect(
			func():
				current_interaction = interaction
				item.interaction_finished.connect(_on_interaction_finished, CONNECT_ONE_SHOT)
				current_state = NPCState.INTERACTING
		)
		interaction_request.rejected.connect(
			func(_reason):
				current_interaction = null
		)
		item.request_interaction.call_deferred(interaction_request)
		return
	
	# No suitable items found
	current_state = NPCState.WANDERING
	set_new_destination()

# NPC Client handlers
func _on_npc_created(event: NpcClientEvents.CreatedEvent) -> void:
	if event.npc_id == npc_id:
		npc_client.get_npc_info(npc_id)

func _on_npc_removed(event: NpcClientEvents.RemovedEvent) -> void:
	if event.npc_id == npc_id:
		npc_id = ""

func _on_action_chosen(event: NpcClientEvents.ActionChosenEvent) -> void:
	# Only handle actions meant for this NPC
	if event.npc_id != npc_id:
		return
		
	var action_name = event.action_name
	var parameters = event.parameters
	match action_name:
		"move_to":
			current_state = NPCState.MOVING_TO_ITEM
			set_new_destination(Vector2i(parameters.x, parameters.y))
		"interact":
			var target_item = null
			var seen_items = _vision_manager.get_items_by_distance()
			for item in seen_items:
				if item.name == parameters.item_name:
					target_item = item
					break
					
			if target_item and target_item.interactions.has(parameters.interaction_type):
				var interaction = target_item.interactions[parameters.interaction_type]
				var interaction_request = interaction.create_start_request(self)
				interaction_request.accepted.connect(
					func():
						current_interaction = interaction
						target_item.interaction_finished.connect(_on_interaction_finished, CONNECT_ONE_SHOT)
						current_state = NPCState.INTERACTING
				)
				interaction_request.rejected.connect(
					func(_reason):
						current_interaction = null
				)
				target_item.request_interaction.call_deferred(interaction_request)
		"wander":
			current_state = NPCState.WANDERING
			set_new_destination()

func _on_npc_error(msg: String) -> void:
	print("NPC Error: ", msg)


################
### Handlers ###
################
func _on_interaction_finished(_interaction_name: String, _npc: NpcController, _payload: Dictionary) -> void:
	current_interaction = null
	decide_behavior()
	
	
func _on_gamepiece_arrived() -> void:
	super._on_gamepiece_arrived()
	decide_behavior()


func _on_focused_gamepiece_changed(new_focused_gamepiece: Gamepiece) -> void:
	if new_focused_gamepiece == _gamepiece:
		reemit_needs()
