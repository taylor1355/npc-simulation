## MCP client for interacting with MCP-based NPC services.
## Uses C# SDK for communication with the MCP server.
class_name McpNpcClient
extends NpcClientBase

# Pending request data structure
class PendingRequest:
	var callback: Callable
	var context: Variant  # String, Dictionary, or null
	var endpoint: String
	var data: Dictionary[String, Variant]
	
	func _init(p_callback: Callable, p_context: Variant, p_endpoint: String, p_data: Dictionary[String, Variant]):
		callback = p_callback
		context = p_context
		endpoint = p_endpoint
		data = p_data
	
	## Execute the request using the provided SDK client
	func execute(request_id: String, sdk_client: Node) -> void:
		match endpoint:
			"create_agent":
				sdk_client.CreateAgent(request_id, data.agent_id, data.config)
			"process_observation":
				sdk_client.ProcessObservation(request_id, data.agent_id, data.observation, data.available_actions)
			"cleanup_agent":
				sdk_client.CleanupAgent(request_id, data.agent_id)
			"get_resource":
				sdk_client.GetResource(request_id, data.resource_path)
			_:
				push_error("Unknown endpoint: " + endpoint)

# Configuration
@export var server_host: String = "localhost"
@export var server_port: int = 3000
@export var debug_mode: bool = true
@export var max_retries: int = 3

# Event formatter
var _event_formatter: EventFormatter

# C# SDK client
var _sdk_client: Node
var _pending_requests: Dictionary[String, PendingRequest] = {}  # request_id -> PendingRequest
var _retry_counts: Dictionary[String, int] = {}  # request_id -> retry_count

signal connection_error(error_message)

func _ready() -> void:
	# Create event formatter
	_event_formatter = EventFormatter.new()
	add_child(_event_formatter)
	
	# Initialize the C# SDK client
	_init_sdk_client()

func _init_sdk_client() -> void:
	# Create an instance of our C# client
	var sdk_client_scene = load("res://src/field/npcs/client/McpSdkClient.tscn")
	_sdk_client = sdk_client_scene.instantiate()
	add_child(_sdk_client)
	
	# Configure the client
	_sdk_client.ServerHost = server_host
	_sdk_client.ServerPort = server_port
	_sdk_client.DebugMode = debug_mode
	
	# Connect signals using PascalCase signal names from C# delegates
	_sdk_client.connect("RequestCompleted", _on_sdk_request_completed)
	_sdk_client.connect("RequestError", _on_sdk_request_error)

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
	
	_send_request(
		"create_agent",
		{
			"agent_id": npc_id,
			"config": config
		},
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
	
	_send_request(
		"process_observation",
		{
			"agent_id": npc_id,
			"observation": observation,
			"available_actions": available_actions
		},
		_on_process_observation_response,
		npc_id
	)

## Removes an NPC and its data
func cleanup_npc(npc_id: String) -> void:
	_npc_cache.erase(npc_id)
	
	_send_request(
		"cleanup_agent",
		{ "agent_id": npc_id },
		_on_cleanup_npc_response,
		npc_id
	)

## Gets information about an NPC
## @param callback: Optional callback to execute after info is received
func get_npc_info(npc_id: String, callback: Callable = Callable()) -> void:
	# Check cache first
	if _npc_cache.has(npc_id) and not _npc_cache[npc_id].working_memory.is_empty():
		FieldEvents.dispatch(NpcClientEvents.create_info_received(
			npc_id,
			_npc_cache[npc_id].traits,
			_npc_cache[npc_id].working_memory
		))
		# Execute callback if provided
		if callback.is_valid():
			callback.call()
		return
	
	# Cache miss - get from server using resource path syntax for MCP
	var resource_path = "agent://" + npc_id + "/info"
	
	# Store callback in context if provided
	var context = { "npc_id": npc_id }
	if callback.is_valid():
		context["callback"] = callback
	
	_send_request(
		"get_resource",
		{ "resource_path": resource_path },
		_on_get_npc_info_response,
		context
	)

# SDK client request handling

func _send_request(endpoint: String, data: Dictionary[String, Variant], callback: Callable, context = null) -> void:
	var request_id = _generate_request_id()
	var pending_request = PendingRequest.new(callback, context, endpoint, data)
	_pending_requests[request_id] = pending_request
	
	if debug_mode:
		print("Sending request to %s: %s" % [endpoint, JSON.stringify(data)])
	
	# Execute the request through the PendingRequest
	pending_request.execute(request_id, _sdk_client)

func _on_sdk_request_completed(request_id: String, response: Dictionary) -> void:
	if not _pending_requests.has(request_id):
		error.emit("Received response for unknown request: " + request_id)
		return
	
	var request_data = _pending_requests[request_id]
	
	if debug_mode:
		print("Received response for %s: %s" % [request_id, JSON.stringify(response)])
	
	# Handle errors if status field indicates an error
	if response.has("status") and response["status"] == "error":
		var error_msg = response.get("message", "Unknown error")
		error.emit(error_msg)
		
		# Still call the callback so it can handle the error if needed
		request_data.callback.call(response, request_data.context)
	else:
		# Execute callback with success response
		request_data.callback.call(response, request_data.context)
		
		if debug_mode:
			print("Callback executed for %s" % request_id)
	
	# Clean up
	_pending_requests.erase(request_id)
	_retry_counts.erase(request_id)

func _on_sdk_request_error(request_id: String, error_msg: String) -> void:
	_handle_request_error(request_id, error_msg)

func _handle_request_error(request_id: String, error_msg: String) -> void:
	if not _pending_requests.has(request_id):
		error.emit("Error for unknown request: " + request_id + " - " + error_msg)
		return
		
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
	if debug_mode:
		print("Processing create_npc response: %s for NPC %s" % [JSON.stringify(response), npc_id])
	
	if response.get("status") == "created":
		_npc_cache.erase(npc_id)
		var event = NpcClientEvents.create_created(npc_id)
		if debug_mode:
			print("Dispatching CreatedEvent for NPC %s" % npc_id)
		FieldEvents.dispatch(event)
	else:
		var error_msg = "Failed to create NPC %s. Status: %s. Message: %s" % [
			npc_id, 
			response.get("status", "unknown"), 
			response.get("message", "No additional message.")
		]
		printerr(error_msg)
		error.emit(error_msg)

func _on_process_observation_response(response: Dictionary, npc_id: String) -> void:
	if debug_mode:
		print("Processing observation response: %s for NPC %s" % [JSON.stringify(response), npc_id])
		
	if response.has("action"):
		var action_name = response.action
		var parameters = response.get("parameters", {})
		
		if debug_mode:
			print("Observation response has action. Refreshing NPC info for %s before dispatching ActionChosenEvent." % npc_id)
		
		# Create callback to dispatch action after info is refreshed
		var dispatch_action_callback = func():
			if debug_mode:
				print("NPC info refreshed for %s. Now dispatching ActionChosenEvent." % npc_id)
			var action_chosen_event = NpcClientEvents.create_action_chosen(npc_id, action_name, parameters)
			if debug_mode:
				print("Dispatching ActionChosenEvent for NPC %s: action=%s" % [npc_id, action_name])
			FieldEvents.dispatch(action_chosen_event)
		
		# Get NPC info with callback
		get_npc_info(npc_id, dispatch_action_callback)
	else:
		print("Warning: Missing 'action' field in observation response")

func _on_cleanup_npc_response(response: Dictionary, npc_id: String) -> void:
	if debug_mode:
		print("Processing cleanup response: %s for NPC %s" % [JSON.stringify(response), npc_id])
		
	if response.get("status") == "removed":
		var event = NpcClientEvents.create_removed(npc_id)
		if debug_mode:
			print("Dispatching RemovedEvent for NPC %s" % npc_id)
		FieldEvents.dispatch(event)
	else:
		print("Warning: Unexpected cleanup_npc response status: %s" % response.get("status", "none"))

func _on_get_npc_info_response(response: Dictionary, context: Dictionary) -> void:
	var npc_id = context.get("npc_id", "")
	
	if debug_mode:
		print("Processing info response: %s for NPC %s" % [JSON.stringify(response), npc_id])
		
	if response.get("status") == "active":
		if not _npc_cache.has(npc_id):
			_npc_cache[npc_id] = NPCState.new()
		
		var incoming_traits_val = response.get("traits", [])
		# The 'traits' property of NPCState is already Array[String].
		# We use 'assign' to populate it from the generic array.
		_npc_cache[npc_id].traits.assign(incoming_traits_val if incoming_traits_val else [])
		_npc_cache[npc_id].working_memory = response.get("working_memory", "")
		
		var event = NpcClientEvents.create_info_received(
			npc_id,
			_npc_cache[npc_id].traits,
			_npc_cache[npc_id].working_memory
		)
		if debug_mode:
			print("Dispatching InfoReceivedEvent for NPC %s" % npc_id)
		FieldEvents.dispatch(event)
		
		# Execute callback if provided in context
		if context.has("callback") and context["callback"] is Callable and context["callback"].is_valid():
			context["callback"].call()
	else:
		print("Warning: Unexpected get_npc_info response status: %s" % response.get("status", "none"))
