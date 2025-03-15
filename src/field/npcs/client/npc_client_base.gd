## Base client for interacting with NPC services. Provides a common interface
## that can be implemented by different backend providers.
class_name NpcClientBase
extends Node

## Emitted when an error occurs
signal error(msg: String)

# Cache of NPC state
class NPCState:
	var traits: Array[String]
	var working_memory: String
	
	func _init(p_traits: Array[String] = [], p_working_memory: String = "") -> void:
		traits = p_traits
		working_memory = p_working_memory

# State cache
var _npc_cache: Dictionary = {} # npc_id -> NPCState

## Gets cached working memory for an NPC
func get_working_memory(npc_id: String) -> String:
	if _npc_cache.has(npc_id):
		return _npc_cache[npc_id].working_memory
	return ""

## Creates a new NPC with the given traits and memories
func create_npc(
	npc_id: String,
	traits: Array[String],
	working_memory: String = "",
	long_term_memories: Array[String] = []
) -> void:
	push_error("NpcClientBase.create_npc() must be implemented by subclasses")

## Processes NPC events to determine next action
func process_observation(npc_id: String, events: Array[NpcEvent]) -> void:
	push_error("NpcClientBase.process_observation() must be implemented by subclasses")

## Removes an NPC and its data
func cleanup_npc(npc_id: String) -> void:
	push_error("NpcClientBase.cleanup_npc() must be implemented by subclasses")

## Gets information about an NPC
func get_npc_info(npc_id: String) -> void:
	push_error("NpcClientBase.get_npc_info() must be implemented by subclasses")
