class_name NpcResponse
extends RefCounted

enum Status {
	SUCCESS,
	ERROR
}

var status: Status
var action: Action.Type
var parameters: Dictionary

func _init(p_status: Status, p_action: Action.Type = Action.Type.WAIT, p_parameters: Dictionary = {}) -> void:
	status = p_status
	action = p_action
	parameters = p_parameters

static func create_success(p_action: Action.Type, parameters: Dictionary = {}) -> NpcResponse:
	return NpcResponse.new(Status.SUCCESS, p_action, parameters)

static func create_error(error_message: String) -> NpcResponse:
	return NpcResponse.new(Status.ERROR, Action.Type.WAIT, {"error_message": error_message})
