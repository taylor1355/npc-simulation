class_name Interaction extends RefCounted

const RequestType = preload("res://src/field/interactions/interaction_request.gd").Type

var name: String
var description: String

signal start_request(request: InteractionRequest)
signal cancel_request(request: InteractionRequest)


func _init(_name: String, _description: String):
	name = _name
	description = _description


func create_start_request(npc: NpcController, arguments: Dictionary = {}) -> InteractionRequest:
	return _create_request(RequestType.START, npc, arguments)


func create_cancel_request(npc: NpcController, arguments: Dictionary = {}) -> InteractionRequest:
	return _create_request(RequestType.CANCEL, npc, arguments)


func _create_request(request_type: RequestType, npc: NpcController, arguments: Dictionary) -> InteractionRequest:
	return InteractionRequest.new(name, request_type, npc, arguments)
