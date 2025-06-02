## Client for simulating interation with the NPC module using a local mock backend.
class_name MockNpcClient
extends NpcClientBase

var _backend: MockNpcBackend

func _ready() -> void:
	_backend = MockNpcBackend.new()
	add_child(_backend)


## Creates a new NPC with the given traits and memories
func create_npc(
	npc_id: String,
	traits: Array[String],
	working_memory: String = "",
	long_term_memories: Array[String] = []
) -> void:
	_npc_cache[npc_id] = NPCState.new(traits, working_memory)
	var create_result = _backend.create_agent(
		npc_id,
		{
			"traits": traits,
			"initial_working_memory": working_memory,
			"initial_long_term_memories": long_term_memories
		}
	)
	if create_result.status == "created":
		# Clear cache to force backend fetch
		_npc_cache.erase(npc_id)
		# Dispatch created event
		EventBus.dispatch(NpcClientEvents.create_created(npc_id))
	else:
		error.emit(create_result.get("message", "Unknown error creating NPC"))

## Processes NPC events to determine next action
func process_observation(npc_id: String, events: Array[NpcEvent]) -> void:
	# Invalidate cache since working memory will be updated
	if _npc_cache.has(npc_id):
		_npc_cache[npc_id].working_memory = ""
	
	var request = NpcRequest.new(npc_id, events)
	var response = _backend.process_observation(request)
	
	if response.status == NpcResponse.Status.SUCCESS:
		var action_name = Action.Type.keys()[response.action].to_lower()
		EventBus.dispatch(NpcClientEvents.create_action_chosen(npc_id, action_name, response.parameters))
		# Get updated working memory after observation
		get_npc_info(npc_id)
	else:
		error.emit(response.parameters.get("error_message", "Unknown error processing observation"))

## Removes an NPC and its data
func cleanup_npc(npc_id: String) -> void:
	_npc_cache.erase(npc_id)
	var result = _backend.cleanup_agent(npc_id)
	if result.status == "removed":
		EventBus.dispatch(NpcClientEvents.create_removed(npc_id))
	else:
		error.emit(result.get("message", "Unknown error cleaning up NPC"))

## Gets information about an NPC
func get_npc_info(npc_id: String) -> void:
	# Check cache first
	if _npc_cache.has(npc_id) and not _npc_cache[npc_id].working_memory.is_empty():
		EventBus.dispatch(NpcClientEvents.create_info_received(
			npc_id,
			_npc_cache[npc_id].traits,
			_npc_cache[npc_id].working_memory
		))
		return
	
	# Cache miss - get from backend
	var result = _backend.get_agent_info(npc_id)
	if result.status == "active":
		# Update cache
		if not _npc_cache.has(npc_id):
			_npc_cache[npc_id] = NPCState.new()
		_npc_cache[npc_id].traits = result.traits
		_npc_cache[npc_id].working_memory = result.working_memory
		
		EventBus.dispatch(NpcClientEvents.create_info_received(npc_id, result.traits, result.working_memory))
	else:
		error.emit(result.get("message", "Unknown error getting NPC info"))
