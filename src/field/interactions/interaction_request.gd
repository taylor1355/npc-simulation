class_name InteractionRequest extends RefCounted

enum RequestType {
	START,
	CANCEL
}

enum Status {
	PENDING,
	ACCEPTED,
	REJECTED
}

var interaction_name: String
var request_type: RequestType
var status: Status
var npc_controller: NpcController
var item_controller: ItemController
var arguments: Dictionary[String, Variant]

signal accepted()
signal rejected(reason: String)


func _init(_interaction_name: String, _request_type: RequestType, _npc: NpcController, _arguments: Dictionary[String, Variant] = {}):
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
