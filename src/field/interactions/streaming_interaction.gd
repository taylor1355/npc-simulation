class_name StreamingInteraction extends Interaction

# Base class for interactions that send observations to participants
# Subclasses decide when to send observations based on their specific logic

func _init(_name: String, _description: String, _requires_adjacency: bool = true):
	super._init(_name, _description, _requires_adjacency)

# Send observations to all participants
func send_observations() -> void:
	for participant in participants:
		var observation = _generate_observation_for_participant(participant)
		if not observation.is_empty():
			send_observation_to_participant(participant, observation)

# Send observation to specific participant
func send_observation_to(participant: NpcController) -> void:
	var observation = _generate_observation_for_participant(participant)
	if not observation.is_empty():
		send_observation_to_participant(participant, observation)

# Override in subclasses to provide participant-specific observations
func _generate_observation_for_participant(participant: NpcController) -> Dictionary:
	var participant_ids = participants.map(func(p): return p.npc_id)
	return {
		"interaction_name": name,
		"participants": participant_ids,
	}
