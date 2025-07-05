extends BaseAgentState

class_name InteractingState

var conversation_state: ConversationUtils.ConversationState = null

func _init(agent_ref):
	super(agent_ref)
	expected_controller_state = "INTERACTING"

func enter() -> void:
	super.enter()
	# Reset conversation state - will be initialized if needed
	conversation_state = null

func _do_update(_seen_items: Array, needs: Dictionary) -> Action:
	# Get current interaction from observation
	if not agent.current_observation:
		return Action.continue_action()
		
	# Extract status observation safely
	var status_obs = _get_status_observation()
	if not status_obs:
		return Action.continue_action()
	
	var current_interaction = status_obs.current_interaction
	
	# If no current interaction, continue in interacting state
	if current_interaction.is_empty():
		# Stay in interacting state until explicitly transitioned out
		return Action.continue_action()
	
	# Check if this is a conversation
	if current_interaction.get("name", "") == "conversation":
		# Initialize conversation state if needed
		if not conversation_state:
			conversation_state = ConversationUtils.ConversationState.new()
		return _handle_conversation_update()
	
	# For non-conversation interactions, use the standard logic
	# Only check needs-based cancellation if we have needs data
	if not needs.is_empty() and NeedUtils.should_cancel_interaction(agent.id, current_interaction, needs):
		return Action.cancel_interaction()
		
	return Action.continue_action()

func _handle_conversation_update() -> Action:
	# Check if we should leave after farewell
	if ConversationUtils.should_leave_after_farewell(conversation_state, Time.get_unix_time_from_system()):
		agent.last_conversation_time = Time.get_unix_time_from_system()
		return Action.cancel_interaction()
	
	# Get conversation observation for context
	var conversation_obs = _get_conversation_observation()
	if not conversation_obs and conversation_state.sent_greeting:
		# Need observation for subsequent messages
		return Action.continue_action()
	
	# Create dummy observation for greeting if needed
	if not conversation_obs:
		conversation_obs = ConversationObservation.new("conversation", [], [])
	
	# Get next message to send
	var message_result = ConversationUtils.get_next_message(conversation_state, agent.id, conversation_obs)
	
	if not message_result.should_send:
		# Still waiting or no message to send
		return Action.continue_action()
	
	# Log the message attempt
	agent.add_observation("Attempting to send: %s" % message_result.message)
	
	return Action.new(
		Action.Type.ACT_IN_INTERACTION,
		{"message": message_result.message}
	)
func _get_status_observation() -> StatusObservation:
	if not agent.current_observation:
		return null
	
	# Handle direct StatusObservation
	if agent.current_observation is StatusObservation:
		return agent.current_observation
	
	# Handle wrapped in CompositeObservation
	elif agent.current_observation is CompositeObservation:
		return agent.current_observation.find_observation(StatusObservation)
	
	return null

func _get_conversation_observation() -> ConversationObservation:
	# First check streaming observations for immediate access
	if agent.streaming_observations.has("conversation"):
		var obs = agent.streaming_observations["conversation"]
		return obs
	
	# Fallback to current_observation for compatibility
	if not agent.current_observation:
		return null
	
	# Handle direct ConversationObservation (streaming)
	if agent.current_observation is ConversationObservation:
		return agent.current_observation
	
	# Handle wrapped in CompositeObservation
	elif agent.current_observation is CompositeObservation:
		var obs = agent.current_observation.find_observation(ConversationObservation)
		return obs
	
	return null

func handle_incoming_interaction_bid(bid_observation: InteractionRequestObservation) -> bool:
	agent.add_observation("Rejected incoming %s - already participating in an interaction" % bid_observation.interaction_name)
	return false

func handle_bid(bid_observation: InteractionRequestObservation) -> Action:
	"""Don't respond to bids while already interacting"""
	# Just log the rejection but don't return an action
	handle_incoming_interaction_bid(bid_observation)
	return null
