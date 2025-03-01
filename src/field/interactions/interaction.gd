class_name Interaction extends RefCounted

const RequestType = preload("res://src/field/interactions/interaction_request.gd").RequestType

var name: String
var description: String
var needs_filled: Array[String]  # Needs this interaction will increase
var needs_drained: Array[String] # Needs this interaction will decrease

signal start_request(request: InteractionRequest)
signal cancel_request(request: InteractionRequest)


func _init(_name: String, _description: String, _fills: Array[String] = [], _drains: Array[String] = []):
	name = _name
	description = _description
	needs_filled = _fills
	needs_drained = _drains


func create_start_request(npc: NpcController, arguments: Dictionary = {}) -> InteractionRequest:
	return _create_request(RequestType.START, npc, arguments)


func create_cancel_request(npc: NpcController, arguments: Dictionary = {}) -> InteractionRequest:
	return _create_request(RequestType.CANCEL, npc, arguments)


func _create_request(request_type: RequestType, npc: NpcController, arguments: Dictionary) -> InteractionRequest:
	return InteractionRequest.new(name, request_type, npc, arguments)
