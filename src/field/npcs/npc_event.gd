class_name NpcEvent
extends RefCounted

enum Type {
	INTERACTION_REQUEST_PENDING,   # When request is first made
	INTERACTION_REQUEST_REJECTED,  # When request is rejected
	INTERACTION_STARTED,          # When interaction begins
	INTERACTION_CANCELED,        # When interaction is canceled
	INTERACTION_FINISHED,         # When interaction completes normally
	OBSERVATION,
	ERROR
}

var timestamp: float
var type: Type
var payload: Dictionary[String, Variant]

func _init(p_type: Type, p_payload: Dictionary[String, Variant]) -> void:
	timestamp = Time.get_unix_time_from_system()
	type = p_type
	payload = p_payload

static func create_interaction_request_event(request: InteractionRequest) -> NpcEvent:
	return NpcEvent.new(
		Type.INTERACTION_REQUEST_PENDING,
		{
			"interaction_name": request.interaction_name,
			"item_name": request.item_controller.name if request.item_controller else &"",
			"request_type": request.request_type
		}
	)

static func create_interaction_rejected_event(request: InteractionRequest, reason: String = "") -> NpcEvent:
	return NpcEvent.new(
		Type.INTERACTION_REQUEST_REJECTED,
		{
			"interaction_name": request.interaction_name,
			"item_name": request.item_controller.name if request.item_controller else &"",
			"request_type": request.request_type,
			"reason": reason
		}
	)

static func create_interaction_update_event(request: InteractionRequest, update_type: Type) -> NpcEvent:
	return NpcEvent.new(
		update_type,
		{
			"interaction_name": request.interaction_name,
			"item_name": request.item_controller.name if request.item_controller else &""
		}
	)

static func create_observation_event(
	position: Vector2i,
	seen_items: Array[Dictionary],
	needs: Dictionary[String, float],
	movement_locked: bool,
	current_interaction: Interaction = null,
	current_request: InteractionRequest = null
) -> NpcEvent:
	var p_payload: Dictionary[String, Variant] = {
		"position": position,
		"seen_items": seen_items,
		"needs": needs,
		"movement_locked": movement_locked,
		"current_interaction": null
	}
	
	if current_interaction:
		var item_name = current_request.item_controller.name if current_request.item_controller else &""
		var item_cell = current_request.item_controller._gamepiece.cell if current_request.item_controller else Vector2i()
		p_payload.current_interaction = current_interaction.to_dict()
		p_payload.current_interaction["item_name"] = item_name
		p_payload.current_interaction["item_cell"] = item_cell
	
	return NpcEvent.new(Type.OBSERVATION, p_payload)

static func create_error_event(message: String) -> NpcEvent:
	return NpcEvent.new(Type.ERROR, {"message": message})
