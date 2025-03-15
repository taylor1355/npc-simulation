extends RefCounted

class_name Action

enum Type {
	MOVE_TO,
	INTERACT_WITH,
	WANDER,
	WAIT,
	CONTINUE,
	CANCEL_INTERACTION
}

var type: Type
var parameters: Dictionary

func _init(action_type: Type, action_parameters: Dictionary = {}):
	type = action_type
	parameters = action_parameters

static func create(action_type: Type, parameters: Dictionary = {}) -> Action:
	"""Create an action with the given type and parameters"""
	return Action.new(action_type, parameters)

static func move_to(x: int, y: int) -> Action:
	"""Create a move to action"""
	return create(Type.MOVE_TO, {"x": x, "y": y})

static func interact_with(item_name: String, interaction_name: String) -> Action:
	"""Create an interact with action"""
	return create(Type.INTERACT_WITH, {
		"item_name": item_name,
		"interaction_name": interaction_name
	})

static func wander() -> Action:
	"""Create a wander action"""
	return create(Type.WANDER)

static func wait() -> Action:
	"""Create a wait action"""
	return create(Type.WAIT)

static func continue_action() -> Action:
	"""Create a continue action"""
	return create(Type.CONTINUE)

static func cancel_interaction() -> Action:
	"""Create a cancel interaction action"""
	return create(Type.CANCEL_INTERACTION)

func format_action() -> String:
	"""Get a human-readable representation of the action"""
	match type:
		Type.MOVE_TO:
			return "move_to(%s, %s)" % [parameters.x, parameters.y]
		Type.INTERACT_WITH:
			return "interact_with(%s, %s)" % [parameters.item_name, parameters.interaction_name]
		Type.WANDER:
			return "wander"
		Type.WAIT:
			return "wait"
		Type.CONTINUE:
			return "continue"
		Type.CANCEL_INTERACTION:
			return "cancel_interaction"
		_:
			return "unknown"

## Get the name of the action as a lowercase string
static func get_name_from_type(action_type: Type) -> String:
	return Type.keys()[action_type].to_lower()

## Get a dictionary describing the action for the MCP server
static func get_action_description(action_type: Type) -> Dictionary:
	match action_type:
		Type.MOVE_TO:
			return {
				"name": get_name_from_type(action_type),
				"description": "Move to a specific cell",
				"parameters": {
					"x": "X coordinate",
					"y": "Y coordinate"
				}
			}
		Type.INTERACT_WITH:
			return {
				"name": get_name_from_type(action_type),
				"description": "Interact with an item",
				"parameters": {
					"item_name": "Name of the item",
					"interaction_name": "Name of the interaction"
				}
			}
		Type.WANDER:
			return {
				"name": get_name_from_type(action_type),
				"description": "Move to a random location",
				"parameters": {}
			}
		Type.WAIT:
			return {
				"name": get_name_from_type(action_type),
				"description": "Do nothing for a moment",
				"parameters": {}
			}
		Type.CONTINUE:
			return {
				"name": get_name_from_type(action_type),
				"description": "Continue current activity",
				"parameters": {}
			}
		Type.CANCEL_INTERACTION:
			return {
				"name": get_name_from_type(action_type),
				"description": "Stop current interaction",
				"parameters": {}
			}
		_:
			return {
				"name": "unknown",
				"description": "Unknown action",
				"parameters": {}
			}

## Get a list of all available action descriptions
static func get_all_action_descriptions() -> Array:
	var descriptions = []
	for i in range(Type.size()):
		descriptions.append(get_action_description(i))
	return descriptions
