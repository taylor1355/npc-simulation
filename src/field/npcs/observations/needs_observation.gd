class_name NeedsObservation extends Observation

var needs: Dictionary  # Dictionary[String, float]
var max_need_value: float

func _init(needs: Dictionary, max_need_value: float):
	self.needs = needs
	self.max_need_value = max_need_value

func get_type() -> String:
	return "needs"

func get_data() -> Dictionary:
	return {
		"needs": needs,
		"max_need_value": max_need_value
	}

func format_for_npc() -> String:
	if needs.is_empty():
		return ""
	
	var parts = ["## Needs"]
	for need_id in needs:
		var percentage = (needs[need_id] / max_need_value) * 100
		parts.append("- %s: %.0f%%" % [need_id.capitalize(), percentage])
	parts.append("")
	
	return "\n".join(parts)