class_name ConversationPanel extends InteractionPanel

## Panel that displays a conversation as a group chat interface.
## Shows message history with participant names and avatars.

@onready var message_container: VBoxContainer = $ScrollContainer/MessageContainer
@onready var scroll_container: ScrollContainer = $ScrollContainer

# Message UI scene
const MESSAGE_SCENE = preload("res://src/ui/panels/conversation_message.tscn")

var _last_message_count: int = 0

func _ready() -> void:
	super._ready()
	# Enable process to check for new messages
	set_process(true)
	# Update display once ready
	_update_display()

func _process(_delta: float) -> void:
	if not current_interaction:
		return
		
	# Check if new messages have been added
	if current_interaction is ConversationInteraction:
		var conversation = current_interaction as ConversationInteraction
		var messages: Array[Dictionary] = conversation.get_messages()
		if messages.size() != _last_message_count:
			_update_conversation_display()
			_last_message_count = messages.size()

func _connect_to_interaction() -> void:
	if current_interaction is ConversationInteraction:
		var conversation = current_interaction as ConversationInteraction
		if conversation.has_signal("message_added"):
			conversation.message_added.connect(_on_message_added)

func _disconnect_from_interaction() -> void:
	if current_interaction and current_interaction is ConversationInteraction:
		var conversation = current_interaction as ConversationInteraction
		if conversation.has_signal("message_added") and conversation.message_added.is_connected(_on_message_added):
			conversation.message_added.disconnect(_on_message_added)

func _on_message_added(message: Dictionary) -> void:
	var message_ui = MESSAGE_SCENE.instantiate()
	message_container.add_child(message_ui)
	message_ui.set_message(
		message.get("speaker_name", "Unknown"),
		message.get("content", ""),
		message.get("timestamp", 0)
	)
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _update_display() -> void:
	_update_conversation_display()

func _update_conversation_display() -> void:
	if not current_interaction or not current_interaction is ConversationInteraction:
		return
	
	# Wait for node to be ready
	if not is_node_ready() or not message_container:
		return
	
	var conversation = current_interaction as ConversationInteraction
	
	# Clear existing messages
	for child in message_container.get_children():
		child.queue_free()
	
	# Add all messages
	var messages: Array[Dictionary] = conversation.get_messages()
	_last_message_count = messages.size()
	
	for msg in messages:
		_on_message_added(msg)
	
	# Add end marker if historical
	if is_historical:
		_add_conversation_end_marker()

func _on_interaction_became_historical() -> void:
	# Stop processing new messages when historical
	set_process(false)
	# Add visual indicator	
	_add_conversation_end_marker()

func _add_conversation_end_marker() -> void:
	# Create a simple label for now - could be a custom scene later
	var end_marker = Label.new()
	end_marker.text = "— Conversation ended —"
	end_marker.modulate = Color(0.7, 0.7, 0.7, 1.0)
	end_marker.add_theme_font_size_override("font_size", 14)
	message_container.add_child(end_marker)
	
	# Auto-scroll to show the end marker
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
