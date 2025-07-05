class_name StreamingInteraction extends Interaction

# Base class for interactions that send observations to participants
# Subclasses decide when to send observations based on their specific logic

const DEFAULT_ACTION_COOLDOWN: float = 2.0  # Default minimum time between actions

var min_seconds_between_actions: float = DEFAULT_ACTION_COOLDOWN
var last_action_times: Dictionary = {}  # Track last action time per participant

func _init(_name: String, _description: String, _requires_adjacency: bool = true, _action_cooldown: float = DEFAULT_ACTION_COOLDOWN):
	super._init(_name, _description, _requires_adjacency)
	min_seconds_between_actions = _action_cooldown

# Get delay needed before participant can perform next action (0 if ready now)
func get_action_delay_for_participant(participant: NpcController) -> float:
	if not last_action_times.has(participant.npc_id):
		return 0.0
	
	var current_time = Time.get_unix_time_from_system()
	var time_since_last = current_time - last_action_times[participant.npc_id]
	var delay_needed = min_seconds_between_actions - time_since_last
	return max(0.0, delay_needed)

# Clean up tracking when participant leaves
func _on_participant_left(participant: NpcController) -> void:
	last_action_times.erase(participant.npc_id)
	super._on_participant_left(participant)

# Send observations to all participants
func send_observations() -> void:
	for participant in participants:
		var observation = _generate_observation_for_participant(participant)
		if observation != null:
			send_observation_to_participant(participant, observation)

# Send observation to specific participant
func send_observation_to(participant: NpcController) -> void:
	var observation = _generate_observation_for_participant(participant)
	if observation != null:
		send_observation_to_participant(participant, observation)

# Override in subclasses to provide participant-specific observations
func _generate_observation_for_participant(participant: NpcController) -> StreamingObservation:
	var participant_ids: Array[String] = []
	participant_ids.assign(participants.map(func(p): return p.npc_id))
	return StreamingObservation.new(name, participant_ids)
