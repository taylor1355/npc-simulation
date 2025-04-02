## MCP client for interacting with MCP-based NPC services.
## Provides the same interface as MockNpcClient but communicates with an external MCP server.
class_name McpNpcClient
extends NpcClientBase

# Configuration
var server_host: String = "localhost"  # Default MCP host
var server_port: int = 3000  # Default MCP port from script
var server_url: String = "http://%s:%d" % [server_host, server_port]
var sse_endpoint: String = "/sse"  # SSE endpoint for the MCP server
var api_url: String = server_url + sse_endpoint  # Full URL for API calls
var request_timeout: int = 10  # seconds
var max_retries: int = 3
var debug_mode: bool = true  # Enable debugging during integration

# HTTP request handling
var _http_request: HTTPRequest
var _pending_requests: Dictionary = {}  # request_id -> {callback, context}
var _retry_counts: Dictionary = {}  # request_id -> retry_count

# Event formatter
var _event_formatter: EventFormatter

signal connection_error(error_message)

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	_http_request.timeout = request_timeout
	
	_event_formatter = EventFormatter.new()
	add_child(_event_formatter)
	
	# Start with a simple ping to check server availability
	_check_server_availability()

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
	
	# Cache miss - get from server using JSON-RPC format for FastMCP
	# Format using resource path syntax for MCP
	var resource_path = "agent://" + npc_id + "/info"
	
	_send_request(
		"get_resource",
		{ "resource_path": resource_path },
		_on_get_npc_info_response,
		npc_id
	)

# HTTP request handling

func _check_server_availability() -> void:
	var ping_request = HTTPRequest.new()
	add_child(ping_request)
	ping_request.request_completed.connect(func(result, code, headers, body):
		if result == HTTPRequest.RESULT_SUCCESS:
			if debug_mode:
				print("Successfully connected to MCP server at %s" % api_url)
		else:
			if debug_mode:
				print("Warning: Could not connect to MCP server at %s" % api_url)
				print("Make sure the run_mcp_server.sh script is running")
			connection_error.emit("Failed to connect to MCP server")
		ping_request.queue_free()
	)
	
	# Send a simple check request to the SSE endpoint
	var err = ping_request.request(api_url)
	if err != OK:
		if debug_mode:
			print("Error sending ping request: ", err)
		connection_error.emit("Failed to connect to MCP server")

func _send_request(endpoint: String, data: Dictionary, callback: Callable, context = null) -> void:
	var request_id = _generate_request_id()
	_pending_requests[request_id] = {
		"callback": callback,
		"context": context,
		"endpoint": endpoint,
		"data": data
	}
	
	var mcp_data = {
		"jsonrpc": "2.0",
		"id": request_id,
		"method": endpoint,
		"params": data
	}
	
	var url = api_url
	var json = JSON.stringify(mcp_data)
	var headers = ["Content-Type: application/json"]
	
	if debug_mode:
		print("Sending request to %s: %s" % [url, json])
	
	var err = _http_request.request(url, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		if debug_mode:
			print("Error sending request: ", err) 
		_handle_request_error(request_id, "Failed to send request")

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
	var json_response = JSON.parse_string(response_text)
	
	if json_response == null:
		_handle_request_error(request_id, "Failed to parse JSON response: %s" % response_text)
		return
	
	if debug_mode:
		print("Received response: %s" % response_text)
	
	# MCP responses include a result field
	var response = {}
	if json_response.has("result"):
		response = json_response.result
	elif json_response.has("error"):
		_handle_request_error(request_id, "API error: %s" % json_response.error.message)
		return
	else:
		_handle_request_error(request_id, "Invalid MCP response format")
		return
	
	# Execute callback
	request_data.callback.call(response, request_data.context)
	
	# Clean up
	_pending_requests.erase(request_id)
	_retry_counts.erase(request_id)

func _handle_request_error(request_id: String, error_msg: String) -> void:
	var retry_count = _retry_counts.get(request_id, 0) + 1
	_retry_counts[request_id] = retry_count
	
	if retry_count <= max_retries:
		var request_data = _pending_requests[request_id]
		var endpoint = request_data.endpoint
		var data = request_data.data
		var callback = request_data.callback
		var context = request_data.context
		
		_pending_requests.erase(request_id)
		
		if debug_mode:
			print("Retrying request to %s (attempt %d/%d)" % [endpoint, retry_count, max_retries])
		
		# Wait before retrying
		var timer = get_tree().create_timer(1.0 * retry_count)
		await timer.timeout
		
		_send_request(endpoint, data, callback, context)
	else:
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
