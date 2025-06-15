class_name NpcEvent
extends RefCounted

enum Type {
	INTERACTION_REQUEST_PENDING,   # When request is first made
	INTERACTION_REQUEST_REJECTED,  # When request is rejected
	INTERACTION_STARTED,          # When interaction begins
	INTERACTION_CANCELED,        # When interaction is canceled
	INTERACTION_FINISHED,         # When interaction completes normally
	OBSERVATION,
	INTERACTION_OBSERVATION,      # When an interaction sends an observation to participants
	ERROR
}

var timestamp: float
var type: Type
var payload: Observation

func _init(p_type: Type, p_payload: Observation) -> void:
	timestamp = Time.get_unix_time_from_system()
	type = p_type
	payload = p_payload

static func create_interaction_request_event(request: InteractionBid) -> NpcEvent:
	var observation = InteractionRequestObservation.new(
		request.interaction_name,
		request.bid_type
	)
	return NpcEvent.new(Type.INTERACTION_REQUEST_PENDING, observation)

static func create_interaction_rejected_event(request: InteractionBid, reason: String = "") -> NpcEvent:
	var observation = InteractionRejectedObservation.new(
		request.interaction_name,
		request.bid_type,
		reason
	)
	return NpcEvent.new(Type.INTERACTION_REQUEST_REJECTED, observation)

static func create_interaction_update_event(request: InteractionBid, update_type: Type) -> NpcEvent:
	var observation = InteractionUpdateObservation.new(
		request.interaction_name,
		update_type
	)
	return NpcEvent.new(update_type, observation)

static func create_observation_event(
	position: Vector2i,
	seen_items: Array[Dictionary],
	needs: Dictionary[String, float],
	movement_locked: bool,
	current_interaction: Interaction = null,
	current_request: InteractionBid = null,
	controller_state: Dictionary = {},
	seen_npcs: Array[Dictionary] = []
) -> NpcEvent:
	var composite = CompositeObservation.new()
	
	# Add status observation
	var interaction_dict = {}
	if current_interaction:
		interaction_dict = current_interaction.to_dict()
	
	composite.add_observation(StatusObservation.new(
		position,
		movement_locked,
		interaction_dict,
		controller_state
	))
	
	# Add needs observation
	if not needs.is_empty():
		composite.add_observation(NeedsObservation.new(needs, Needs.MAX_VALUE))
	
	# Add vision observation
	if not seen_items.is_empty() or not seen_npcs.is_empty():
		var visible_entities: Array[Dictionary] = []
		visible_entities.append_array(seen_items)
		visible_entities.append_array(seen_npcs)
		composite.add_observation(VisionObservation.new(visible_entities))
	
	return NpcEvent.new(Type.OBSERVATION, composite)

static func create_interaction_observation_event(
	interaction_name: String,
	observation_data: Dictionary
) -> NpcEvent:
	# TODO: Create a generic StreamingObservation when we have more streaming interaction types
	# For now, we'll use ConversationObservation for conversation interactions
	var participants = observation_data.get("participants", [])
	var history = observation_data.get("conversation_history", [])
	var observation = ConversationObservation.new(interaction_name, participants, history)
	return NpcEvent.new(Type.INTERACTION_OBSERVATION, observation)

static func create_error_event(message: String) -> NpcEvent:
	var observation = ErrorObservation.new(message)
	return NpcEvent.new(Type.ERROR, observation)
