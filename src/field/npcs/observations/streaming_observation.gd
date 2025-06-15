class_name StreamingObservation extends Observation

var interaction_name: String
var participants: Array[String]

func _init(interaction_name: String, participants: Array[String]):
	self.interaction_name = interaction_name
	self.participants = participants

func get_type() -> String:
	return "streaming_observation"

func get_data() -> Dictionary:
	return {
		"interaction_name": interaction_name,
		"participants": participants
	}

func format_for_npc() -> String:
	return "In %s with: %s" % [interaction_name, ", ".join(participants)]