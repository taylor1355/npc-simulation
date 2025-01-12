## Client for interacting with NPC services. Provides a domain-specific interface
## that internally communicates with the backend agent system.
class_name NpcClient
extends Node

## Emitted when an NPC is created
signal npc_created(npc_id: String)
## Emitted when an NPC is removed
signal npc_removed(npc_id: String)
## Emitted when NPC info is received
signal npc_info_received(npc_id: String, traits: Array[String], working_memory: String)
## Emitted when an action is chosen
signal action_chosen(action_name: String, parameters: Dictionary)
## Emitted when an error occurs
signal error(msg: String)

# Cache of NPC state
class NPCState:
	var traits: Array[String]
	var working_memory: String
	
	func _init(p_traits: Array[String] = [], p_working_memory: String = "") -> void:
		traits = p_traits
		working_memory = p_working_memory

class Action:
	var name: String
	var description: String
	var parameters: Dictionary
	
	func _init(p_name: String, p_description: String, p_parameters: Dictionary = {}) -> void:
		name = p_name
		description = p_description
		parameters = p_parameters
	
	func to_dict() -> Dictionary:
		return {
			"name": name,
			"description": description,
			"parameters": parameters
		}

var _backend: MockNpcBackend
var _npc_cache: Dictionary = {} # npc_id -> NPCState

func _ready() -> void:
	_backend = MockNpcBackend.new()
	add_child(_backend)

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
	# Initialize cache
	_npc_cache[npc_id] = NPCState.new(traits, working_memory)
	var config = {
		"traits": traits,
		"initial_working_memory": working_memory,
		"initial_long_term_memories": long_term_memories
	}
	
	var result = _backend.create_agent(npc_id, config)
	if result.status == "created":
		npc_created.emit(npc_id)
	else:
		error.emit(result.get("message", "Unknown error creating NPC"))

## Processes an observation and available actions for the NPC
func process_observation(npc_id: String, observation: String, available_actions: Array[Action]) -> void:
	# Invalidate cache since working memory will be updated
	if _npc_cache.has(npc_id):
		_npc_cache[npc_id].working_memory = ""

	# Convert Action objects to dictionaries
	var action_dicts = []
	for action in available_actions:
		action_dicts.append(action.to_dict())
	
	var result = _backend.process_observation(npc_id, observation, action_dicts)
	if result.has("action"):
		action_chosen.emit(result.action, result.parameters)
	else:
		error.emit(result.get("message", "Unknown error processing observation"))

## Removes an NPC and its data
func cleanup_npc(npc_id: String) -> void:
	_npc_cache.erase(npc_id)
	var result = _backend.cleanup_agent(npc_id)
	if result.status == "removed":
		npc_removed.emit(npc_id)
	else:
		error.emit(result.get("message", "Unknown error cleaning up NPC"))

## Gets information about an NPC
func get_npc_info(npc_id: String) -> void:
	# Check cache first
	if _npc_cache.has(npc_id) and not _npc_cache[npc_id].working_memory.is_empty():
		npc_info_received.emit(npc_id, _npc_cache[npc_id].traits, _npc_cache[npc_id].working_memory)
		return
	
	# Cache miss - get from backend
	var result = _backend.get_agent_info(npc_id)
	if result.status == "active":
		# Update cache
		if not _npc_cache.has(npc_id):
			_npc_cache[npc_id] = NPCState.new()
		_npc_cache[npc_id].traits = result.traits
		_npc_cache[npc_id].working_memory = result.working_memory
		
		npc_info_received.emit(npc_id, result.traits, result.working_memory)
	else:
		error.emit(result.get("message", "Unknown error getting NPC info"))
