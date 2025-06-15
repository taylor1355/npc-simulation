class_name ErrorObservation extends Observation

var message: String

func _init(message: String):
	self.message = message

func get_type() -> String:
	return "error"

func get_data() -> Dictionary:
	return {
		"message": message
	}

func format_for_npc() -> String:
	return "[ERROR] %s" % message