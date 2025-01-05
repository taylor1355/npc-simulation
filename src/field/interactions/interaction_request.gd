class_name InteractionRequest extends RefCounted

enum Type {
	START,
	CANCEL
}

enum Status {
	PENDING,
	ACCEPTED,
	REJECTED
}

var interaction_name: String
var request_type: Type
var status: Status
var npc_controller: NpcController
var item_controller: ItemController
var arguments: Dictionary

signal accepted()
signal rejected(reason: String)


func _init(_interaction_name: String, _request_type: Type, _npc: NpcController, _arguments: Dictionary = {}):
	interaction_name = _interaction_name
	request_type = _request_type
	npc_controller = _npc
	arguments = _arguments

	status = Status.PENDING


func accept():
	status = Status.ACCEPTED
	accepted.emit()
	

func reject(reason: String):
	status = Status.REJECTED
	rejected.emit(reason)
