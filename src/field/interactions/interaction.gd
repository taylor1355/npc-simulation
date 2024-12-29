class_name Interaction extends RefCounted

var name: String
var description: String

signal start_request(request: InteractionRequest)
signal cancel_request(request: InteractionRequest)


func _init(_name: String, _description: String):
	name = _name
	description = _description


func create_start_request(npc: NpcController, arguments: Dictionary = {}) -> InteractionRequest:
	return _create_request("start", npc, arguments)


func create_cancel_request(npc: NpcController, arguments: Dictionary = {}) -> InteractionRequest:
	return _create_request("cancel", npc, arguments)


func _create_request(request_type: String, npc: NpcController, arguments: Dictionary) -> InteractionRequest:
	return InteractionRequest.new(name, request_type, npc, arguments)
