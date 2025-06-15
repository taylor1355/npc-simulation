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

	# Assign handlers
	self.on_start_handler = _handle_start
	self.on_participant_joined_handler = _handle_participant_joined
	self.on_participant_left_handler = _handle_participant_left

func _handle_start(_interaction: Interaction, _context: Dictionary) -> void:
	started_at = Time.get_unix_time_from_system()
	
	# Log conversation start
	ConversationLogger.log_conversation_event("STARTED", conversation_id, {
		"participants": participants.map(func(p): return p.npc_id)
	})
	
	# Send initial observation to all participants
	send_observations()

func _handle_participant_joined(_interaction: Interaction, participant: NpcController) -> void:
	participant.set_movement_locked(true)
	
	# Log participant joined
	ConversationLogger.log_conversation_event("PARTICIPANT_JOINED", conversation_id, {
		"participant": participant.npc_id
	})

func _handle_participant_left(_interaction: Interaction, participant: NpcController) -> void:
	participant.set_movement_locked(false)
	
	# Log participant left
	ConversationLogger.log_conversation_event("PARTICIPANT_LEFT", conversation_id, {
		"participant": participant.npc_id
	})

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

func _on_end() -> void:
	super._on_end()
	
	# Log conversation end
	var duration = Time.get_unix_time_from_system() - started_at if started_at > 0.0 else 0.0
	ConversationLogger.log_conversation_event("ENDED", conversation_id, {
		"duration": duration
	})
