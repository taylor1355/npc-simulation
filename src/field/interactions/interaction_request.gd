class_name InteractionRequest extends RefCounted

var interaction_name: String
var request_type: String # TODO: make this an enum
var status: String # TODO: make this an enum
var npc_controller: NpcController
var item_controller: ItemController
var arguments: Dictionary

signal accepted()
signal rejected(reason: String)


func _init(_interaction_name: String, _request_type: String, _npc: NpcController, _arguments: Dictionary = {}):
	interaction_name = _interaction_name
	request_type = _request_type
	npc_controller = _npc
	arguments = _arguments

	status = "pending"


func accept():
	status = "accepted"
	accepted.emit()
	

func reject(reason: String):
	status = "rejected"
	rejected.emit(reason)
