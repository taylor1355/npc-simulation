extends Node

# Test script for the McpNpcClient
# This can be run as a standalone scene to verify connectivity
# to the MCP server without depending on the full NPC controller

@onready var mcp_client = McpNpcClient.new()
var test_npc_id = "test-npc-1"
var test_status_label: Label

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
	
	# Add client
	add_child(mcp_client)
	mcp_client.error.connect(_on_error)
	mcp_client.connection_error.connect(_on_connection_error)
	
	# Connect to event bus 
	FieldEvents.event_dispatched.connect(_on_field_event)
	
	# Use a timer to sequence our tests
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_run_tests)
	timer.start()
	
	log_message("MCP NPC Client test starting in 2 seconds...")

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
	var events = []
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
					"needs_filled": ["hunger"],
					"needs_drained": []
				}
			}
		}],
		{"hunger": 50.0, "energy": 80.0},
		false
	))
	
	# Process observation
	mcp_client.process_observation(test_npc_id, events)

func test_cleanup_npc():
	log_message("Testing cleanup_npc...")
	
	# Cleanup NPC
	mcp_client.cleanup_npc(test_npc_id)

func _on_field_event(event: Event):
	if event is NpcClientEvents.CreatedEvent:
		var created_event = event as NpcClientEvents.CreatedEvent
		if created_event.npc_id == test_npc_id:
			log_message("✓ NPC Created successfully: " + test_npc_id)
			test_get_npc_info()
	
	elif event is NpcClientEvents.InfoReceivedEvent:
		var info_event = event as NpcClientEvents.InfoReceivedEvent
		if info_event.npc_id == test_npc_id:
			log_message("✓ NPC Info received:")
			log_message("  Traits: " + str(info_event.traits))
			log_message("  Working Memory: " + info_event.working_memory)
			test_process_observation()
	
	elif event is NpcClientEvents.ActionChosenEvent:
		var action_event = event as NpcClientEvents.ActionChosenEvent
		if action_event.npc_id == test_npc_id:
			log_message("✓ Action chosen:")
			log_message("  Action: " + action_event.action_name)
			log_message("  Parameters: " + str(action_event.parameters))
			test_cleanup_npc()
	
	elif event is NpcClientEvents.RemovedEvent:
		var removed_event = event as NpcClientEvents.RemovedEvent
		if removed_event.npc_id == test_npc_id:
			log_message("✓ NPC Removed successfully: " + test_npc_id)
			log_message("✅ All tests completed!")

func _on_error(msg: String):
	log_message("❌ ERROR: " + msg)
	
func _on_connection_error(msg: String):
	log_message("❌ Connection error: " + msg)
	
func log_message(msg: String):
	print(msg)
	if test_status_label:
		test_status_label.text += "\n" + msg
