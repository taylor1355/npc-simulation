class_name Interaction extends RefCounted

const RequestType = preload("res://src/field/interactions/interaction_request.gd").RequestType

var name: String
var description: String
var needs_filled: Array[Needs.Need]  # Needs this interaction will increase
var needs_drained: Array[Needs.Need] # Needs this interaction will decrease

signal start_request(request: InteractionRequest)
signal cancel_request(request: InteractionRequest)


func _init(_name: String, _description: String, _fills: Array[Needs.Need] = [], _drains: Array[Needs.Need] = []):
	name = _name
	description = _description
	needs_filled = _fills
	needs_drained = _drains



func create_start_request(npc: NpcController, arguments: Dictionary[String, Variant] = {}) -> InteractionRequest:
	return _create_request(RequestType.START, npc, arguments)


func create_cancel_request(npc: NpcController, arguments: Dictionary[String, Variant] = {}) -> InteractionRequest:
	return _create_request(RequestType.CANCEL, npc, arguments)


func _create_request(request_type: RequestType, npc: NpcController, arguments: Dictionary[String, Variant]) -> InteractionRequest:
	return InteractionRequest.new(name, request_type, npc, arguments)

# Serialization method for backend communication
func to_dict() -> Dictionary[String, Variant]:
	return {
		"name": name,
		"description": description,
		"needs_filled": needs_filled.map(func(need): return Needs.get_display_name(need)),
		"needs_drained": needs_drained.map(func(need): return Needs.get_display_name(need))
	}
