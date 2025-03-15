## HTTP client for interacting with MCP-based NPC services.
## Provides the same interface as MockNpcClient but communicates with an external server.
class_name HttpNpcClient
extends NpcClientBase

# Configuration
var server_url: String = "http://localhost:8000"
var request_timeout: int = 10  # seconds
var max_retries: int = 3
var debug_mode: bool = false

# HTTP request handling
var _http_request: HTTPRequest
var _pending_requests: Dictionary = {}  # request_id -> {callback, context}
var _retry_counts: Dictionary = {}  # request_id -> retry_count


# Event formatter
var _event_formatter: EventFormatter

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	
	_event_formatter = EventFormatter.new()
	add_child(_event_formatter)


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
	
	var data = {
		"agent_id": npc_id,
		"config": config
	}
	
	_send_request(
		"create_agent",
		data,
		_on_create_npc_response,
		npc_id
	)

## Processes NPC events to determine next action
func process_observation(npc_id: String, events: Array[NpcEvent]) -> void:
	# Invalidate cache since working memory will be updated
	if _npc_cache.has(npc_id):
		_npc_cache[npc_id].working_memory = ""
	
	# Get NPC position from events
	var npc_position = Vector2i.ZERO
	var max_need_value = 100.0
	
	for event in events:
		if event.type == NpcEvent.Type.OBSERVATION:
			npc_position = event.payload.get("position", Vector2i.ZERO)
			break
	
	# Format events as text observation
	var observation = _event_formatter.format_events_as_observation(
		events,
		npc_position,
		max_need_value
	)
	
	# Define available actions
	var available_actions = _event_formatter.get_available_actions()
	
	var data = {
		"agent_id": npc_id,
		"observation": observation,
		"available_actions": available_actions
	}
	
	_send_request(
		"process_observation",
		data,
		_on_process_observation_response,
		npc_id
	)

## Removes an NPC and its data
func cleanup_npc(npc_id: String) -> void:
	_npc_cache.erase(npc_id)
	
	var data = {
		"agent_id": npc_id
	}
	
	_send_request(
		"cleanup_agent",
		data,
		_on_cleanup_npc_response,
		npc_id
	)

## Gets information about an NPC
func get_npc_info(npc_id: String) -> void:
	# Check cache first
	if _npc_cache.has(npc_id) and not _npc_cache[npc_id].working_memory.is_empty():
		FieldEvents.dispatch(NpcClientEvents.create_info_received(
			npc_id,
			_npc_cache[npc_id].traits,
			_npc_cache[npc_id].working_memory
		))
		return
	
	# Cache miss - get from server
	# For MCP resources, we'll use a direct HTTP GET request
	var url = "%s/resource/agent:/%s/info" % [server_url, npc_id]
	var headers = []
	
	var request_id = _generate_request_id()
	_pending_requests[request_id] = {
		"callback": _on_get_npc_info_response,
		"context": npc_id
	}
	
	_http_request.request(url, headers, HTTPClient.METHOD_GET)

# HTTP request handling

func _send_request(endpoint: String, data: Dictionary, callback: Callable, context = null) -> void:
	var request_id = _generate_request_id()
	_pending_requests[request_id] = {
		"callback": callback,
		"context": context,
		"endpoint": endpoint,
		"data": data
	}
	
	var url = "%s/%s" % [server_url, endpoint]
	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	if debug_mode:
		print("Sending request to %s: %s" % [url, json])
	
	_http_request.request(url, headers, HTTPClient.METHOD_POST, json)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var request_id = _pending_requests.keys()[0] if not _pending_requests.is_empty() else ""
	if request_id.is_empty():
		error.emit("Received response with no pending request")
		return
	
	var request_data = _pending_requests[request_id]
	
	# Handle HTTP errors
	if result != HTTPRequest.RESULT_SUCCESS:
		_handle_request_error(request_id, "HTTP request failed with code: %d" % result)
		return
	
	if response_code != 200:
		_handle_request_error(request_id, "HTTP request returned error code: %d" % response_code)
		return
	
	# Parse response
	var response_text = body.get_string_from_utf8()
	var response = JSON.parse_string(response_text)
	
	if response == null:
		_handle_request_error(request_id, "Failed to parse JSON response: %s" % response_text)
		return
	
	if debug_mode:
		print("Received response: %s" % response_text)
	
	# Execute callback
	request_data.callback.call(response, request_data.context)
	
	# Clean up
	_pending_requests.erase(request_id)
	_retry_counts.erase(request_id)

func _handle_request_error(request_id: String, error_msg: String) -> void:
	if not _retry_counts.has(request_id):
		_retry_counts[request_id] = 0
	
	_retry_counts[request_id] += 1
	
	if _retry_counts[request_id] <= max_retries:
		# Retry the request
		var request_data = _pending_requests[request_id]
		var endpoint = request_data.endpoint
		var data = request_data.data
		var callback = request_data.callback
		var context = request_data.context
		
		# Remove from pending requests
		_pending_requests.erase(request_id)
		
		# Wait a moment before retrying
		await get_tree().create_timer(0.5 * _retry_counts[request_id]).timeout
		
		if debug_mode:
			print("Retrying request to %s (attempt %d/%d)" % [endpoint, _retry_counts[request_id], max_retries])
		
		# Send the request again
		_send_request(endpoint, data, callback, context)
	else:
		# Max retries reached, emit error
		error.emit(error_msg)
		_pending_requests.erase(request_id)
		_retry_counts.erase(request_id)

func _generate_request_id() -> String:
	return "%d_%d" % [Time.get_unix_time_from_system() * 1000, randi() % 1000]

# Response handlers

func _on_create_npc_response(response: Dictionary, npc_id: String) -> void:
	if response.get("status") == "created":
		# Clear cache to force backend fetch
		_npc_cache.erase(npc_id)
		# Dispatch created event
		FieldEvents.dispatch(NpcClientEvents.create_created(npc_id))
	else:
		error.emit(response.get("message", "Unknown error creating NPC"))

func _on_process_observation_response(response: Dictionary, npc_id: String) -> void:
	if response.has("action"):
		var action_name = response.action
		var parameters = response.get("parameters", {})
		
		FieldEvents.dispatch(NpcClientEvents.create_action_chosen(
			npc_id, 
			action_name, 
			parameters
		))
		
		# Get updated working memory after observation
		get_npc_info(npc_id)
	else:
		error.emit(response.get("message", "Unknown error processing observation"))

func _on_cleanup_npc_response(response: Dictionary, npc_id: String) -> void:
	if response.get("status") == "removed":
		FieldEvents.dispatch(NpcClientEvents.create_removed(npc_id))
	else:
		error.emit(response.get("message", "Unknown error cleaning up NPC"))

func _on_get_npc_info_response(response: Dictionary, npc_id: String) -> void:
	if response.get("status") == "active":
		# Update cache
		if not _npc_cache.has(npc_id):
			_npc_cache[npc_id] = NPCState.new()
		
		_npc_cache[npc_id].traits = response.get("traits", [])
		_npc_cache[npc_id].working_memory = response.get("working_memory", "")
		
		FieldEvents.dispatch(NpcClientEvents.create_info_received(
			npc_id,
			_npc_cache[npc_id].traits,
			_npc_cache[npc_id].working_memory
		))
	else:
		error.emit(response.get("message", "Unknown error getting NPC info"))
