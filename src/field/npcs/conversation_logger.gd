class_name ConversationLogger extends RefCounted

static func log_conversation_event(event_type: String, conversation_id: String, details: Dictionary) -> void:
	var timestamp = Time.get_unix_time_from_system()
	var log_entry = "[CONVERSATION] [%s] %s:" % [conversation_id, event_type]
	
	match event_type:
		"STARTED":
			print("%s Started with participants: %s" % [log_entry, details.get("participants", [])])
		"MESSAGE":
			# Make messages more prominent with speakers' names
			var speaker = details.get("speaker_name", details.get("speaker_id", "Unknown"))
			var message = details.get("message", "")
			print("💬 [%s] %s: \"%s\"" % [conversation_id.substr(0, 8), speaker, message])
		"PARTICIPANT_JOINED":
			print("%s %s joined" % [log_entry, details.get("participant", "Unknown")])
		"PARTICIPANT_LEFT":
			print("%s %s left" % [log_entry, details.get("participant", "Unknown")])
		"ENDED":
			print("%s Ended after %.1f seconds" % [log_entry, details.get("duration", 0.0)])