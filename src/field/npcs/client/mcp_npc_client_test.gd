extends Node

# Test script for the McpNpcClient
# This can be run as a standalone scene to verify connectivity
# to the MCP server without depending on the full NPC controller

@onready var mcp_client := McpNpcClient.new()
var test_npc_id: String = "test-npc-1"
var test_status_label: Label

# State tracking to prevent race conditions
var info_received_count: int = 0
var action_chosen_count: int = 0
var is_cleaning_up: bool = false

func _ready():
	# Create a simple UI for test status
	var margin = MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	add_child(margin)
	
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Add status label
	test_status_label = Label.new()
	test_status_label.text = "Initializing test..."
	vbox.add_child(test_status_label)
	
	# Create and configure the MCP client
	mcp_client = McpNpcClient.new()
	add_child(mcp_client)
	mcp_client.debug_mode = true  # Enable debugging
	mcp_client.error.connect(_on_error)
	mcp_client.connection_error.connect(_on_connection_error)
	
	# Connect to event bus 
	FieldEvents.event_dispatched.connect(_on_field_event)
	
	# Add a direct callback for a sanity check
	log_message("Setting up manual callback test")
	_setup_direct_callback_test()
	
	# Use a timer to sequence our tests
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_run_tests)
	timer.start()
	
	log_message("MCP NPC Client test starting in 2 seconds...")

# Direct callback test to verify signals are working
func _setup_direct_callback_test():
	var direct_timer = Timer.new()
	add_child(direct_timer)
	direct_timer.wait_time = 5.0
	direct_timer.one_shot = true
	direct_timer.timeout.connect(func():
		log_message("⚠️ Testing direct FieldEvents dispatch")
		var direct_event = NpcClientEvents.create_created(test_npc_id)
		FieldEvents.dispatch(direct_event)
	)
	direct_timer.start()

func _run_tests():
	log_message("Starting tests...")
	test_create_npc()

func test_create_npc():
	log_message("Testing create_npc...")
	
	# Create the NPC
	mcp_client.create_npc(
		test_npc_id,
		["friendly", "curious"],
		"I am a test NPC.",
		["I was created for testing purposes."]
	)

func test_get_npc_info():
	log_message("Testing get_npc_info...")
	
	# Get NPC info
	mcp_client.get_npc_info(test_npc_id)

func test_process_observation():
	log_message("Testing process_observation...")
	
	# Create a test observation
	var events: Array[NpcEvent] = []
	events.append(NpcEvent.create_observation_event(
		Vector2i(5, 5),
		[{
			"name": "Apple", 
			"cell": Vector2i(3, 3), 
			"distance_to_npc": 2,
			"interactions": {
				"consume": {
					"name": "consume",
					"description": "Eat the apple",
					"needs_filled": [Needs.get_display_name(Needs.Need.HUNGER)],
					"needs_drained": []
				}
			}
		}],
		{
			Needs.get_display_name(Needs.Need.HUNGER): 50.0,
			Needs.get_display_name(Needs.Need.ENERGY): 80.0
		},
		false
	))
	
	# Process observation
	mcp_client.process_observation(test_npc_id, events)

func test_cleanup_npc():
	log_message("Testing cleanup_npc...")
	
	# Set flag to ignore further events
	is_cleaning_up = true
	
	# Cleanup NPC
	mcp_client.cleanup_npc(test_npc_id)

func _on_field_event(event: Event):
	# Ignore events if we're cleaning up
	if is_cleaning_up and event.event_type != Event.Type.NPC_REMOVED:
		return
		
	log_message("Received field event: " + event.get_class())
	
	# Check for event types by event_type enum rather than by class
	match event.event_type:
		Event.Type.NPC_CREATED:
			var created_event = event as NpcClientEvents.CreatedEvent
			if created_event.npc_id == test_npc_id:
				log_message("✓ NPC Created successfully: " + test_npc_id)
				test_get_npc_info()
		
		Event.Type.NPC_INFO_RECEIVED:
			var info_event = event as NpcClientEvents.InfoReceivedEvent
			if info_event.npc_id == test_npc_id:
				info_received_count += 1
				log_message("✓ NPC Info received (count: %d):" % info_received_count)
				log_message("  Traits: " + str(info_event.traits))
				log_message("  Working Memory: " + info_event.working_memory)
				
				# Only process observation on first info received
				if info_received_count == 1:
					test_process_observation()
		
		Event.Type.NPC_ACTION_CHOSEN:
			var action_event = event as NpcClientEvents.ActionChosenEvent
			if action_event.npc_id == test_npc_id:
				action_chosen_count += 1
				log_message("✓ Action chosen (count: %d):" % action_chosen_count)
				log_message("  Action: " + action_event.action_name)
				log_message("  Parameters: " + str(action_event.parameters))
				
				# Only cleanup on first action chosen
				if action_chosen_count == 1:
					# Add a small delay before cleanup to let pending requests finish
					var cleanup_timer = Timer.new()
					add_child(cleanup_timer)
					cleanup_timer.wait_time = 0.5
					cleanup_timer.one_shot = true
					cleanup_timer.timeout.connect(test_cleanup_npc)
					cleanup_timer.start()
		
		Event.Type.NPC_REMOVED:
			var removed_event = event as NpcClientEvents.RemovedEvent
			if removed_event.npc_id == test_npc_id:
				log_message("✓ NPC Removed successfully: " + test_npc_id)
				log_message("✅ All tests completed!")
		
		_:
			log_message("Received other event type: " + str(event.event_type))

func _on_error(msg: String):
	# Ignore "Agent not found" errors during cleanup
	if is_cleaning_up and msg.contains("not found"):
		log_message("(Expected during cleanup) " + msg)
	else:
		log_message("❌ ERROR: " + msg)
	
func _on_connection_error(msg: String):
	log_message("❌ Connection error: " + msg)
	
func log_message(msg: String):
	print(msg)
	if test_status_label:
		test_status_label.text += "\n" + msg
		
# Add additional debug hook for request responses
func _enter_tree():
	# Add global signal hooks to see all signals
	var debug_client = McpNpcClient.new()
	debug_client.set_name("DebugMcpClient")
	debug_client.debug_mode = true
	# Don't add the client in _enter_tree to avoid having two instances
