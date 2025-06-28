class_name ConversationInteraction extends StreamingInteraction

const MAX_HISTORY_SIZE: int = 10  # Maximum messages to keep in history
const MAX_HISTORY_IN_OBSERVATION: int = 5  # Maximum messages to include in observations

var conversation_history: Array[Dictionary] = []
var conversation_id: String
var started_at: float

func _init():
	super._init(
		"conversation",
		"Multi-party conversation",
		false # Doesn't require adjacency (conversations can happen at distance)
	)
	
	# Allow multiple participants
	max_participants = 10
	min_participants = 2
	
	# Define expected act_in_interaction parameters
	act_in_interaction_parameters["message"] = PropertySpec.string_property(
		"message",
		"",
		"Message text to send in conversation"
	)
	
	conversation_id = IdGenerator.generate_conversation_id()

func _on_start(context: Dictionary) -> void:
	started_at = Time.get_unix_time_from_system()
	
	# Log conversation start
	ConversationLogger.log_conversation_event("STARTED", conversation_id, {
		"participants": participants.map(func(p): return p.npc_id)
	})
	
	# Send initial observation to all participants
	send_observations()
	
	# Call super last to dispatch event
	super._on_start(context)

func _on_participant_joined(participant: NpcController) -> void:
	participant.set_movement_locked(true)
	
	# Log participant joined
	ConversationLogger.log_conversation_event("PARTICIPANT_JOINED", conversation_id, {
		"participant": participant.npc_id
	})
	
	# Call super last to dispatch event
	super._on_participant_joined(participant)

func _on_participant_left(participant: NpcController) -> void:
	participant.set_movement_locked(false)
	
	# Log participant left
	ConversationLogger.log_conversation_event("PARTICIPANT_LEFT", conversation_id, {
		"participant": participant.npc_id
	})
	
	# Call super last to dispatch event
	super._on_participant_left(participant)

func handle_act_in_interaction(participant: NpcController, parameters: Dictionary) -> void:
	# Early return for empty messages
	var message = parameters.get("message", "").strip_edges()
	if message.is_empty():
		return
	
	# Validate participant is still in conversation
	if participant not in participants:
		push_warning("Participant %s not in conversation %s" % [participant.npc_id, conversation_id])
		return
	
	# Add message to conversation history
	var message_entry = {
		"speaker": participant.npc_id,
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	}
	conversation_history.append(message_entry)
	
	# Limit history size
	if conversation_history.size() > MAX_HISTORY_SIZE:
		conversation_history.pop_front()
	
	# Log the message
	ConversationLogger.log_conversation_event("MESSAGE", conversation_id, {
		"speaker": participant.npc_id,
		"message": message
	})
	
	# Send observation to all participants about the new message
	send_observations()

func _generate_observation_for_participant(participant: NpcController) -> Dictionary:
	var observation = super._generate_observation_for_participant(participant)
	# TODO: Using system time is inflexible, need to add a game clock
	var current_time = Time.get_unix_time_from_system()
	
	observation["conversation_id"] = conversation_id
	observation["conversation_history"] = conversation_history.slice(-MAX_HISTORY_IN_OBSERVATION)
	observation["duration"] = current_time - started_at if started_at > 0.0 else 0.0
	
	return observation

func _on_end(context: Dictionary) -> void:
	# Log conversation end
	var duration = Time.get_unix_time_from_system() - started_at if started_at > 0.0 else 0.0
	ConversationLogger.log_conversation_event("ENDED", conversation_id, {
		"duration": duration
	})
	
	# Call super last to dispatch event
	super._on_end(context)

func get_interaction_emoji() -> String:
	return "💬"

# Override to add participant state validation
func send_observations() -> void:
	# Validate participant states before sending observations
	_validate_participant_states()
	
	# Call super to send observations
	super.send_observations()

func _validate_participant_states() -> void:
	# Check if all participants are actually in conversation state
	var invalid_participants: Array[NpcController] = []
	
	for participant in participants:
		var state_machine = participant.state_machine
		var is_in_conversation = (
			state_machine.current_state is ControllerInteractingState and
			participant.current_interaction == self
		)
		
		if not is_in_conversation:
			print("[CONVERSATION WARNING] Participant %s is not in conversation state (state: %s, interaction: %s)" % [
				participant.npc_id,
				state_machine.current_state.state_name if state_machine.current_state else "None",
				participant.current_interaction.name if participant.current_interaction else "None"
			])
			invalid_participants.append(participant)
	
	# Remove participants who are not actually in the conversation
	for invalid_participant in invalid_participants:
		participants.erase(invalid_participant)
		_on_participant_left(invalid_participant)
