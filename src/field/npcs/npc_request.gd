class_name NpcRequest
extends RefCounted

var npc_id: String
var events: Array[NpcEvent]

func _init(p_npc_id: String, p_events: Array[NpcEvent]) -> void:
	npc_id = p_npc_id
	events = p_events
