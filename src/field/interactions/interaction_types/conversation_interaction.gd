class_name ConversationInteraction extends StreamingInteraction

const MAX_HISTORY_SIZE: int = 10  # Maximum messages to keep in history
const MAX_HISTORY_IN_OBSERVATION: int = 5  # Maximum messages to include in observations
const MESSAGE_COOLDOWN_SECONDS: float = 3.0  # Time between messages

var conversation_history: Array[Dictionary] = []
var conversation_id: String
var started_at: float

func _init():
	super._init(
		"conversation",
		"Multi-party conversation",
		false, # Doesn't require adjacency (conversations can happen at distance)
		MESSAGE_COOLDOWN_SECONDS
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
	
	var participant_names = participants.map(func(p): return p.npc_id)
	print("\n🗣️ ===== NEW CONVERSATION STARTED =====")
	print("   Participants: %s" % str(participant_names))
	print("   Conversation ID: %s" % conversation_id)
	print("==========================================\n")
	
	# Log conversation start
	ConversationLogger.log_conversation_event("STARTED", conversation_id, {
		"participants": participants.map(func(p): return p.npc_id)
	})
	
	# Don't send observations immediately - wait for participants to transition to InteractingState
	# This will be done when _on_participant_joined is called for each participant
	
	# Call super last to dispatch event
	super._on_start(context)

func _on_participant_joined(participant: NpcController) -> void:
	participant.set_movement_locked(true)
	
	# Log participant joined
	ConversationLogger.log_conversation_event("PARTICIPANT_JOINED", conversation_id, {
		"participant": participant.npc_id
	})
	
	# Send observation to the new participant
	send_observation_to(participant)
	
	# Call super last to dispatch event
	super._on_participant_joined(participant)

func _on_participant_left(participant: NpcController) -> void:
	participant.set_movement_locked(false)
	
	# Log participant left
	ConversationLogger.log_conversation_event("PARTICIPANT_LEFT", conversation_id, {
		"participant": participant.npc_id
	})
	
	# Call super last to dispatch event (base class handles min_participants check)
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
	
	# Check if enough time has passed since participant's last message
	var delay_needed = get_action_delay_for_participant(participant)
	if delay_needed > 0.0:
		return
	
	# Record that this participant sent a message
	last_action_times[participant.npc_id] = Time.get_unix_time_from_system()
	
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

func _generate_observation_for_participant(participant: NpcController) -> ConversationObservation:
	var participant_ids: Array[String] = []
	participant_ids.assign(participants.map(func(p): return p.npc_id))
	var recent_history: Array[Dictionary] = []
	recent_history.assign(conversation_history.slice(-MAX_HISTORY_IN_OBSERVATION))
	
	return ConversationObservation.new(name, participant_ids, recent_history)

func _on_end(context: Dictionary) -> void:
	# Unlock movement for any remaining participants
	for participant in participants:
		participant.set_movement_locked(false)
	
	var duration = Time.get_unix_time_from_system() - started_at if started_at > 0.0 else 0.0
	print("\n🏁 ===== CONVERSATION ENDED =====")
	print("   Duration: %.1f seconds" % duration)
	print("   Total messages: %d" % conversation_history.size())
	print("   Conversation ID: %s" % conversation_id)
	print("=================================\n")
	
	# Log conversation end
	ConversationLogger.log_conversation_event("ENDED", conversation_id, {
		"duration": duration
	})
	
	# Call super last to dispatch event
	super._on_end(context)

func get_interaction_emoji() -> String:
	return "💬"

# Override to add participant state validation
func send_observations() -> void:
	# Simply send observations without validation
	# The interaction system already handles participant lifecycle properly
	super.send_observations()
