class_name Needs
extends RefCounted

enum Need { HUNGER, HYGIENE, FUN, ENERGY }

const MAX_VALUE: float = 100.0
const NEED_NAMES: Array[String] = ["hunger", "hygiene", "fun", "energy"]

static func get_display_name(need: Need) -> String:
	match need:
		Need.HUNGER: return "hunger"
		Need.HYGIENE: return "hygiene"
		Need.FUN: return "fun"
		Need.ENERGY: return "energy"
		_: return "unknown"

static func parse_need_name(need_name: String) -> Need:
	"""Convert a string need name to the corresponding Need enum value."""
	match need_name.to_lower():
		"hunger": return Need.HUNGER
		"hygiene": return Need.HYGIENE
		"fun": return Need.FUN
		"energy": return Need.ENERGY
		_: 
			push_error("Unknown need name: " + need_name)
			return Need.HUNGER  # TODO: Handle this case more gracefully

static func serialize_need_dict(need_dict: Dictionary[Need, float]) -> Dictionary[String, float]:
	"""Convert a Need enum dictionary to a string dictionary for serialization."""
	var result: Dictionary[String, float] = {}
	for need in need_dict:
		result[get_display_name(need)] = need_dict[need]
	return result

static func deserialize_need_dict(string_dict: Dictionary[String, float]) -> Dictionary[Need, float]:
	"""Convert a string dictionary to a Need enum dictionary."""
	var result: Dictionary[Need, float] = {}
	for need_name in string_dict:
		var need_enum = parse_need_name(need_name)
		result[need_enum] = string_dict[need_name]
	return result
