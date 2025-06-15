class_name InteractionRejectedObservation extends Observation

var interaction_name: String
var request_type: InteractionBid.BidType
var reason: String

func _init(interaction_name: String, request_type: InteractionBid.BidType, reason: String = ""):
	self.interaction_name = interaction_name
	self.request_type = request_type
	self.reason = reason

func get_type() -> String:
	return "interaction_rejected"

func get_data() -> Dictionary:
	return {
		"interaction_name": interaction_name,
		"request_type": request_type,
		"reason": reason
	}

func format_for_npc() -> String:
	var parts = ["Interaction request rejected: %s" % interaction_name]
	if not reason.is_empty():
		parts.append("Reason: %s" % reason)
	return "\n".join(parts)