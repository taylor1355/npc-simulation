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

static func interact_with(item_name: String, interaction_type: String) -> Action:
	"""Create an interact with action"""
	return create(Type.INTERACT_WITH, {
		"item_name": item_name,
		"interaction_type": interaction_type
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
			return "interact_with(%s, %s)" % [parameters.item_name, parameters.interaction_type]
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
