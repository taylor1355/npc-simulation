extends RefCounted

class_name Action

enum Type {
	MOVE_TO,
	INTERACT_WITH,
	WANDER,
	WAIT,
	CONTINUE,
	ACT_IN_INTERACTION,
	CANCEL_INTERACTION,
	# Conversation actions
	START_CONVERSATION
}

var type: Type
var parameters: Dictionary[String, Variant]

func _init(action_type: Type, action_parameters: Dictionary[String, Variant] = {}):
	type = action_type
	parameters = action_parameters

static func move_to(x: int, y: int) -> Action:
	"""Create a move to action"""
	return Action.new(Type.MOVE_TO, {"x": x, "y": y})

static func interact_with(entity_name: String, interaction_name: String) -> Action:
	"""Create an interact with action"""
	return Action.new(Type.INTERACT_WITH, {
		"entity_name": entity_name,
		"interaction_name": interaction_name
	})

static func wander() -> Action:
	"""Create a wander action"""
	return Action.new(Type.WANDER)

static func wait() -> Action:
	"""Create a wait action"""
	return Action.new(Type.WAIT)

static func continue_action() -> Action:
	"""Create a continue action"""
	return Action.new(Type.CONTINUE)

static func act_in_interaction(parameters: Dictionary[String, Variant] = {}) -> Action:
	"""Create an act in interaction action"""
	return Action.new(Type.ACT_IN_INTERACTION, parameters)

static func cancel_interaction() -> Action:
	"""Create a cancel interaction action"""
	return Action.new(Type.CANCEL_INTERACTION)

static func start_conversation(npc_ids: Array[String]) -> Action:
	"""Create a start conversation action"""
	return Action.new(Type.START_CONVERSATION, {
		"npc_ids": npc_ids
	})


func format_action() -> String:
	"""Get a human-readable representation of the action"""
	match type:
		Type.MOVE_TO:
			return "move_to(%s, %s)" % [parameters.x, parameters.y]
		Type.INTERACT_WITH:
			return "interact_with(%s, %s)" % [parameters.entity_name, parameters.interaction_name]
		Type.WANDER:
			return "wander"
		Type.WAIT:
			return "wait"
		Type.CONTINUE:
			return "continue"
		Type.ACT_IN_INTERACTION:
			return "act_in_interaction(%s)" % [parameters]
		Type.CANCEL_INTERACTION:
			return "cancel_interaction"
		Type.START_CONVERSATION:
			return "start_conversation(%s)" % [parameters.get("npc_ids", [])]
		_:
			return "unknown"

## Get the name of the action as a lowercase string
static func get_name_from_type(action_type: Type) -> String:
	return Type.keys()[action_type].to_lower()

## Get a dictionary describing the action for the MCP server
static func get_action_description(action_type: Type) -> Dictionary[String, Variant]:
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
				"description": "Interact with an item or NPC",
				"parameters": {
					"entity_name": "Name of the entity (item or NPC)",
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
		Type.ACT_IN_INTERACTION:
			return {
				"name": get_name_from_type(action_type),
				"description": "Provide input to current interaction",
				"parameters": {}
			}
		Type.CANCEL_INTERACTION:
			return {
				"name": get_name_from_type(action_type),
				"description": "Stop current interaction",
				"parameters": {}
			}
		Type.START_CONVERSATION:
			return {
				"name": get_name_from_type(action_type),
				"description": "Start a conversation with other NPCs",
				"parameters": {
					"npc_ids": "Array of NPC IDs to converse with"
				}
			}
		_:
			return {
				"name": "unknown",
				"description": "Unknown action",
				"parameters": {}
			}

## Get a list of all available action descriptions
static func get_all_action_descriptions() -> Array[Dictionary]:
	var descriptions: Array[Dictionary] = []
	for i in range(Type.size()):
		descriptions.append(get_action_description(i))
	return descriptions
