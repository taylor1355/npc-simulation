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
						
						# Update state based on current interaction
						if not status_obs.current_interaction.is_empty():
							if not (agent.current_state is InteractingState):
								agent.change_state(InteractingState)
						elif agent.current_state is InteractingState:
							agent.change_state(IdleState)
					
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
					# Go back to idle if we were requesting an interaction
					if agent.current_state is RequestingInteractionState:
						agent.change_state(IdleState)
			NpcEvent.Type.INTERACTION_STARTED:
				if event.payload is InteractionUpdateObservation:
					agent.add_observation("Interaction started: %s" % event.payload.interaction_name)
			NpcEvent.Type.INTERACTION_OBSERVATION:
				if event.payload is ConversationObservation:
					var conv_obs = event.payload as ConversationObservation
					agent.add_observation("In conversation with %d participants" % conv_obs.participants.size())
					
					# Log recent messages
					for msg in conv_obs.conversation_history.slice(-3):
						agent.add_observation("%s said: %s" % [msg["speaker"], msg["message"]])
			NpcEvent.Type.INTERACTION_CANCELED, NpcEvent.Type.INTERACTION_FINISHED:
				agent.idle_timer = MOVEMENT_COOLDOWN
				
				if event.payload is InteractionUpdateObservation:
					# Log appropriate message
					var action = "canceled" if event.type == NpcEvent.Type.INTERACTION_CANCELED else "finished"
					agent.add_observation("Interaction %s: %s" % [action, event.payload.interaction_name])
		
		agent.last_processed_event_timestamp = event.timestamp
	
	var action = agent.choose_action(seen_items, needs)
	agent.update_state_from_action(action)
	
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
