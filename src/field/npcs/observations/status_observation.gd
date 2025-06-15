class_name StatusObservation extends Observation

var position: Vector2i
var movement_locked: bool
var current_interaction: Dictionary  # from Interaction.to_dict()
var controller_state: Dictionary

func _init(
	position: Vector2i,
	movement_locked: bool,
	current_interaction: Dictionary = {},
	controller_state: Dictionary = {}
):
	self.position = position
	self.movement_locked = movement_locked
	self.current_interaction = current_interaction
	self.controller_state = controller_state

func get_type() -> String:
	return "status"

func get_data() -> Dictionary:
	return {
		"position": position,
		"movement_locked": movement_locked,
		"current_interaction": current_interaction,
		"controller_state": controller_state
	}

func format_for_npc() -> String:
	var parts = []
	
	# Add position
	parts.append("## Position")
	parts.append("You are at position (%d,%d)." % [position.x, position.y])
	
	# Format current interaction
	if not current_interaction.is_empty():
		parts.append("")
		parts.append("## Current Interaction")
		parts.append("You are currently %s." % current_interaction.get("name", "unknown"))
	
	# Format controller state
	if not controller_state.is_empty():
		parts.append("")
		parts.append("## Controller State")
		parts.append("- State: %s" % controller_state.get("state_enum", "UNKNOWN"))
		var context_data = controller_state.get("context_data", {})
		if not context_data.is_empty():
			for key in context_data:
				var value = context_data[key]
				if key == "conversation_info" and value is Dictionary:
					parts.append(_format_conversation_info(value))
				elif value is Dictionary and value.has("x") and value.has("y"):
					parts.append("- %s: (%d,%d)" % [key.capitalize(), value.x, value.y])
				else:
					parts.append("- %s: %s" % [key.capitalize(), str(value)])
	
	parts.append("")
	return "\n".join(parts)

func _format_conversation_info(info: Dictionary) -> String:
	var conv_parts = ["## Conversation"]
	conv_parts.append("- Status: %s" % info.get("state", "UNKNOWN"))
	
	var conv_id = info.get("conversation_id", "")
	if not conv_id.is_empty():
		conv_parts.append("- Conversation ID: %s" % conv_id)
	
	var participants = info.get("participants", [])
	if not participants.is_empty():
		conv_parts.append("- Participants: %s" % ", ".join(participants))
	
	var duration = info.get("duration", 0.0)
	if duration > 0:
		conv_parts.append("- Duration: %.1f seconds" % duration)
	
	var can_leave = info.get("can_leave", false)
	conv_parts.append("- Can leave: %s" % ("Yes" if can_leave else "No"))
	
	return "\n".join(conv_parts)