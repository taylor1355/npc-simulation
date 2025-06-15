extends BaseAgentState

class_name InteractingState

var conversation_turn_count: int = 0
var sent_greeting: bool = false

func enter() -> void:
	super.enter()
	conversation_turn_count = 0
	sent_greeting = false

func update(_seen_items: Array, needs: Dictionary) -> Action:
	# Get current interaction from observation
	if not agent.current_observation:
		return Action.wait()
		
	# Extract status observation from composite
	var status_obs = agent.current_observation
	if agent.current_observation is CompositeObservation:
		status_obs = agent.current_observation.find_observation(StatusObservation)
		if not status_obs:
			return Action.wait()
	
	var current_interaction = status_obs.current_interaction
	if current_interaction.is_empty():
		return Action.wait()
	
	# Check if this is a conversation
	if current_interaction.get("name", "") == "conversation":
		return _handle_conversation_update()
	
	# For non-conversation interactions, use the standard logic
	if NeedUtils.should_cancel_interaction(agent.id, current_interaction, needs):
		return Action.cancel_interaction()
		
	return Action.continue_action()

func _handle_conversation_update() -> Action:
	# Check if we have a conversation observation
	var conversation_obs = _get_conversation_observation()
	if not conversation_obs:
		# No conversation data, continue waiting
		return Action.continue_action()
	
	conversation_turn_count += 1
	
	# Leave after several turns
	if conversation_turn_count > 4 and randf() < 0.3:
		agent.last_conversation_time = Time.get_unix_time_from_system()
		return Action.cancel_interaction()
	
	# Send appropriate message based on conversation state
	var message: String
	if not sent_greeting:
		message = ConversationPhrases.get_random_greeting()
		sent_greeting = true
		agent.add_observation("Sending greeting: %s" % message)
	elif conversation_turn_count >= 4:
		# Getting ready to leave
		message = ConversationPhrases.get_random_farewell()
		agent.add_observation("Sending farewell: %s" % message)
	else:
		message = ConversationPhrases.get_random_response()
		agent.add_observation("Sending response: %s" % message)
	
	return Action.new(
		Action.Type.ACT_IN_INTERACTION,
		{"message": message}
	)

func _get_conversation_observation() -> ConversationObservation:
	if not agent.current_observation:
		return null
	return agent.current_observation.find_observation(ConversationObservation)
