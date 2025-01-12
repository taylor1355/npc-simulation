class_name NpcClientEvents extends RefCounted

## Collection of NPC client-related event classes

class CreatedEvent extends Event:
	var npc_id: String
	
	func _init(id: String) -> void:
		super(Type.NPC_CREATED)
		npc_id = id

class RemovedEvent extends Event:
	var npc_id: String
	
	func _init(id: String) -> void:
		super(Type.NPC_REMOVED)
		npc_id = id

class InfoReceivedEvent extends Event:
	var npc_id: String
	var traits: Array[String]
	var working_memory: String
	
	func _init(id: String, p_traits: Array[String], memory: String) -> void:
		super(Type.NPC_INFO_RECEIVED)
		npc_id = id
		traits = p_traits
		working_memory = memory

class ActionChosenEvent extends Event:
	var npc_id: String
	var action_name: String
	var parameters: Dictionary
	
	func _init(id: String, name: String, params: Dictionary) -> void:
		super(Type.NPC_ACTION_CHOSEN)
		npc_id = id
		action_name = name
		parameters = params

## Static factory methods
static func create_created(npc_id: String) -> CreatedEvent:
	return CreatedEvent.new(npc_id)

static func create_removed(npc_id: String) -> RemovedEvent:
	return RemovedEvent.new(npc_id)

static func create_info_received(npc_id: String, traits: Array[String], working_memory: String) -> InfoReceivedEvent:
	return InfoReceivedEvent.new(npc_id, traits, working_memory)

static func create_action_chosen(npc_id: String, action_name: String, parameters: Dictionary) -> ActionChosenEvent:
	return ActionChosenEvent.new(npc_id, action_name, parameters)
