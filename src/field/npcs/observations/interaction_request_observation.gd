class_name InteractionRequestObservation extends Observation

var interaction_name: String
var request_type: InteractionBid.BidType
var bid_id: String

func _init(interaction_name: String, request_type: InteractionBid.BidType, bid_id: String = ""):
	self.interaction_name = interaction_name
	self.request_type = request_type
	self.bid_id = bid_id

func get_type() -> String:
	return "interaction_request"

func get_data() -> Dictionary:
	return {
		"interaction_name": interaction_name,
		"request_type": request_type,
		"bid_id": bid_id
	}

func format_for_npc() -> String:
	var action = "start" if request_type == InteractionBid.BidType.START else "cancel"
	return "Requesting to %s interaction: %s" % [action, interaction_name]
