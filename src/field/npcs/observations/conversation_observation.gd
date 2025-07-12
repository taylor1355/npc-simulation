class_name ConversationObservation extends StreamingObservation

var conversation_history: Array[Dictionary]

func _init(interaction_name: String, participants: Array[String], history: Array[Dictionary]):
	super(interaction_name, participants)
	self.conversation_history = history

func get_type() -> String:
	return "conversation_observation"

func get_data() -> Dictionary:
	var data = super.get_data()
	data["conversation_history"] = conversation_history
	return data

func format_for_npc() -> String:
	var parts = ["[Conversation Update]"]
	parts.append("Participants: %s" % ", ".join(participants))
	
	if conversation_history.is_empty():
		parts.append("No messages yet.")
	else:
		parts.append("Recent messages:")
		var recent_count = min(5, conversation_history.size())
		for i in range(conversation_history.size() - recent_count, conversation_history.size()):
			var msg = conversation_history[i]
			parts.append("  %s: %s" % [msg.get("speaker_name", msg.get("speaker_id", "Unknown")), msg.get("message", "")])
	
	return "\n".join(parts)