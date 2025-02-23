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
var payload: Dictionary

func _init(p_type: Type, p_payload: Dictionary) -> void:
	timestamp = Time.get_unix_time_from_system()
	type = p_type
	payload = p_payload

static func create_interaction_request_event(request: InteractionRequest) -> NpcEvent:
	return NpcEvent.new(
		Type.INTERACTION_REQUEST_PENDING,
		{
			"interaction_type": request.interaction_name,
			"item_name": request.item_controller.name if request.item_controller else "",
			"request_type": request.request_type
		}
	)

static func create_interaction_rejected_event(request: InteractionRequest, reason: String = "") -> NpcEvent:
	var payload = {
		"interaction_type": request.interaction_name,
		"item_name": request.item_controller.name if request.item_controller else "",
		"request_type": request.request_type,
		"reason": reason
	}
	return NpcEvent.new(Type.INTERACTION_REQUEST_REJECTED, payload)

static func create_interaction_update_event(request: InteractionRequest, update_type: Type) -> NpcEvent:
	return NpcEvent.new(
		update_type,
		{
			"interaction_type": request.interaction_name,
			"item_name": request.item_controller.name if request.item_controller else ""
		}
	)

static func create_observation_event(
	position: Vector2i,
	seen_items: Array,
	needs: Dictionary,
	movement_locked: bool,
	current_interaction: Interaction = null,
	current_request: InteractionRequest = null
) -> NpcEvent:
	var payload = {
		"position": position,
		"seen_items": seen_items,
		"needs": needs,
		"movement_locked": movement_locked,
		"current_interaction": null
	}
	
	if current_interaction:
		var item_name = current_request.item_controller.name if current_request.item_controller else ""
		var item_cell = current_request.item_controller._gamepiece.cell if current_request.item_controller else Vector2i()
		payload.current_interaction = {
			"interaction_type": current_interaction.name,
			"item_name": item_name,
			"item_cell": item_cell
		}
	
	return NpcEvent.new(Type.OBSERVATION, payload)

static func create_error_event(message: String) -> NpcEvent:
	return NpcEvent.new(
		Type.ERROR,
		{
			"message": message
		}
	)
