## Mock implementation of the NPC agent backend service. This simulates the server-side
## logic that would normally run remotely. Uses "agent" terminology to match the real backend.
class_name MockNpcBackend
extends Node

const MOVEMENT_COOLDOWN = 0.75  # How long to idle after movement

# Backend state
var agents: Dictionary = {}  # Dictionary of agent_id -> Agent

func create_agent(agent_id: String, config: Dictionary[String, Variant]) -> Dictionary[String, String]:
	"""Create a new agent
	
	Args:
		agent_id: Unique identifier for the agent
		config: Configuration object containing:
			- traits: list[str], Basic personality traits
			- initial_working_memory: str, Initial working memory state
			- initial_long_term_memories: list[str], Initial long-term memories
	"""
	agents[agent_id] = Agent.new(agent_id, config)
	
	return {
		"status": "created",
		"agent_id": agent_id
	}

func process_observation(request: NpcRequest) -> NpcResponse:
	"""Process NPC events and return chosen action"""
	if not agents.has(request.npc_id):
		return NpcResponse.create_error("Agent %s not found" % request.npc_id)
	
	var agent = agents[request.npc_id]
	var needs = {}
	var seen_items = []
	
	# First pass: Find the latest observation and sync state immediately
	var latest_observation = null
	var latest_status_obs = null
	for event in request.events:
		if event.type == NpcEvent.Type.OBSERVATION and event.payload is CompositeObservation:
			latest_observation = event.payload
			var status_obs = event.payload.find_observation(StatusObservation)
			if status_obs:
				latest_status_obs = status_obs
	
	# Sync state BEFORE processing any events
	if latest_status_obs:
		var controller_state = latest_status_obs.controller_state.get("state_enum", "")
		if controller_state:
			_sync_agent_state(agent, controller_state, latest_status_obs)
	
	# Process events in order
	for event in request.events:
		if event.timestamp < agent.last_processed_event_timestamp:
			continue
			
		match event.type:
			NpcEvent.Type.OBSERVATION:
				if event.payload is CompositeObservation:
					# Extract data from composite observation
					var status_obs = event.payload.find_observation(StatusObservation)
					if status_obs:
						agent.movement_locked = status_obs.movement_locked
						agent.current_observation = status_obs
					
					var needs_obs = event.payload.find_observation(NeedsObservation)
					if needs_obs:
						needs = needs_obs.needs
					
					var vision_obs = event.payload.find_observation(VisionObservation)
					if vision_obs:
						seen_items = vision_obs.visible_entities
				else:
					push_warning("Unexpected observation type: " + str(event.payload))
				
				# Store the composite observation for state decisions
				agent.current_observation = event.payload
			NpcEvent.Type.ERROR:
				if event.payload is ErrorObservation:
					agent.add_observation("Error: " + event.payload.message)
			NpcEvent.Type.INTERACTION_REQUEST_PENDING:
				if event.payload is InteractionRequestObservation:
					agent.add_observation("Requesting interaction: %s" % event.payload.interaction_name)
			NpcEvent.Type.INTERACTION_REQUEST_REJECTED:
				if event.payload is InteractionRejectedObservation:
					agent.add_observation("Interaction request rejected: %s (%s)" % [
						event.payload.interaction_name,
						event.payload.reason
					])
			NpcEvent.Type.INTERACTION_BID_RECEIVED:
				if event.payload is InteractionRequestObservation:
					# Let the current state handle the bid and optionally return an action
					var bid_action = agent.current_state.handle_bid(event.payload)
					if bid_action:
						return NpcResponse.create_success(bid_action.type, bid_action.parameters)
			NpcEvent.Type.INTERACTION_STARTED:
				if event.payload is InteractionUpdateObservation:
					agent.add_observation("Interaction started: %s" % event.payload.interaction_name)
					# Transition to interacting state immediately to match controller state
					if not (agent.current_state is InteractingState):
						agent.change_state(InteractingState)
			NpcEvent.Type.INTERACTION_OBSERVATION:
				if event.payload is ConversationObservation:
					var conv_obs = event.payload as ConversationObservation
					
					agent.add_observation("In conversation with %d participants" % conv_obs.participants.size())
					
					# Store streaming observation for immediate access by InteractingState
					agent.streaming_observations["conversation"] = conv_obs
					
					# Log recent messages
					for msg in conv_obs.conversation_history.slice(-3):
						agent.add_observation("%s said: %s" % [msg.get("speaker_name", msg.get("speaker_id", "Unknown")), msg["message"]])
			NpcEvent.Type.INTERACTION_CANCELED, NpcEvent.Type.INTERACTION_FINISHED:
				agent.idle_timer = MOVEMENT_COOLDOWN
				
				if event.payload is InteractionUpdateObservation:
					# Log appropriate message
					var action = "canceled" if event.type == NpcEvent.Type.INTERACTION_CANCELED else "finished"
					agent.add_observation("Interaction %s: %s" % [action, event.payload.interaction_name])
		
		agent.last_processed_event_timestamp = event.timestamp
	
	var action = agent.choose_action(seen_items, needs)
	
	return NpcResponse.create_success(action.type, action.parameters)

func cleanup_agent(agent_id: String) -> Dictionary:
	"""Gracefully cleanup and remove an agent from the system
	
	Args:
		agent_id: Agent to remove
	"""
	if agents.has(agent_id):
		agents.erase(agent_id)
		
	return {
		"status": "removed",
		"agent_id": agent_id
	}

func get_agent_info(agent_id: String) -> Dictionary:
	"""Get basic information about an agent in the system"""
	if not agents.has(agent_id):
		return {
			"status": "error",
			"message": "Agent %s not found" % agent_id
		}
		
	var agent = agents[agent_id]
	return {
		"status": "active",
		"traits": agent.traits,
		"working_memory": "\n".join(agent.working_memory)
	}

func _sync_agent_state(agent: Agent, controller_state: String, status_obs: StatusObservation) -> void:
	"""Sync agent state with controller state from observations"""
	# Store controller state for validation
	agent.controller_state = controller_state
	
	# Map controller states to agent states
	match controller_state:
		"IDLE":
			if not (agent.current_state is IdleState):
				agent.change_state(IdleState)
		
		"WANDERING":
			if not (agent.current_state is WanderingState):
				agent.change_state(WanderingState)
		
		"MOVING":
			# Moving could be targeted movement or wandering
			if agent.target_position:
				if not (agent.current_state is MovingToTargetState):
					agent.change_state(MovingToTargetState)
			else:
				# No target = treat as wandering
				if not (agent.current_state is WanderingState):
					agent.change_state(WanderingState)
		
		"REQUESTING":
			if not (agent.current_state is RequestingInteractionState):
				agent.change_state(RequestingInteractionState)
		
		"INTERACTING":
			if not (agent.current_state is InteractingState):
				agent.change_state(InteractingState)
		
		"WAITING":
			# Waiting maps to idle in the agent
			if not (agent.current_state is IdleState):
				agent.change_state(IdleState)
		
		_:
			# Unknown state - default to idle
			if not (agent.current_state is IdleState):
				push_warning("[MockNpcBackend] Unknown controller state: %s" % controller_state)
				agent.change_state(IdleState)
