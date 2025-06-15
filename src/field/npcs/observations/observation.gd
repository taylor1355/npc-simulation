class_name Observation extends RefCounted

func format_for_npc() -> String:
	push_error("format_for_npc() must be implemented by subclass")
	return ""

func get_type() -> String:
	push_error("get_type() must be implemented by subclass")
	return "unknown"

func get_data() -> Dictionary:
	return {}