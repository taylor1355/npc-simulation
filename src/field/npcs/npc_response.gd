class_name NpcResponse
extends RefCounted

enum Status {
	SUCCESS,
	ERROR
}

enum Action {
	MOVE_TO,
	INTERACT_WITH,
	WANDER,
	WAIT,
	CONTINUE,
	CANCEL_INTERACTION
}

var status: Status
var action: Action
var parameters: Dictionary

func _init(p_status: Status, p_action: Action = -1, p_parameters: Dictionary = {}) -> void:
	status = p_status
	action = p_action
	parameters = p_parameters

static func create_success(action: Action, parameters: Dictionary = {}) -> NpcResponse:
	return NpcResponse.new(Status.SUCCESS, action, parameters)

static func create_error(error_message: String) -> NpcResponse:
	return NpcResponse.new(Status.ERROR, -1, {"error_message": error_message})
