class_name ConversationVisualHandler extends BaseVisualHandler

var line: Line2D
var _is_highlighted: bool = false

func _on_setup() -> void:
	# Create line
	line = Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.5, 0.5, 1.0, 0.5)  # Semi-transparent blue
	line.z_index = 10
	
	# TODO: Add dotted texture for a more subtle look
	# var texture = preload("res://assets/ui/dotted_line.png")
	# line.texture = texture
	# line.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	add_child(line)
	
	# Connect to highlight signals
	var tracker = UIRegistry.get_state_tracker()
	tracker.interaction_highlighted.connect(_on_interaction_highlighted)
	tracker.interaction_unhighlighted.connect(_on_interaction_unhighlighted)

func _process(_delta: float) -> void:
	if participants.is_empty():
		return
		
	# Update line to connect all participants
	var points = PackedVector2Array()
	for npc in participants:
		if is_instance_valid(npc) and npc.get_gamepiece():
			var pos = npc.get_gamepiece().global_position
			points.append(to_local(pos))
	
	# Only update if we have at least 2 points
	if points.size() >= 2:
		line.points = points
		line.visible = true
	else:
		line.visible = false

func _on_participant_added(npc: NpcController) -> void:
	# Force update when participant added
	_process(0.0)

func _on_participant_removed(npc: NpcController) -> void:
	# Force update when participant removed
	_process(0.0)

# Source ID for color manager
const SOURCE_ID = "conversation_highlight"

func _highlight_participants() -> void:
	for npc in participants:
		if is_instance_valid(npc) and npc.get_gamepiece():
			var gamepiece = npc.get_gamepiece()
			# Apply highlight color through manager
			SpriteColorManager.apply_color(gamepiece, SOURCE_ID, Color(1.2, 1.2, 0.8, 1.0))

func _unhighlight_participants() -> void:
	for npc in participants:
		if is_instance_valid(npc) and npc.get_gamepiece():
			var gamepiece = npc.get_gamepiece()
			# Remove highlight color through manager
			SpriteColorManager.remove_color(gamepiece, SOURCE_ID)

func _exit_tree() -> void:
	# Ensure we restore colors when handler is destroyed
	_unhighlight_participants()
	
	# Disconnect signals
	var tracker = UIRegistry.get_state_tracker()
	if tracker.interaction_highlighted.is_connected(_on_interaction_highlighted):
		tracker.interaction_highlighted.disconnect(_on_interaction_highlighted)
	if tracker.interaction_unhighlighted.is_connected(_on_interaction_unhighlighted):
		tracker.interaction_unhighlighted.disconnect(_on_interaction_unhighlighted)

func _on_interaction_highlighted(highlighted_id: String) -> void:
	if highlighted_id == interaction_id:
		_is_highlighted = true
		# Update visual appearance
		line.width = 4.0
		line.default_color = Color(1.0, 1.0, 0.5, 0.8)  # Bright yellow
		_highlight_participants()

func _on_interaction_unhighlighted(unhighlighted_id: String) -> void:
	if unhighlighted_id == interaction_id:
		_is_highlighted = false
		# Restore normal appearance
		line.width = 2.0
		line.default_color = Color(0.5, 0.5, 1.0, 0.5)  # Semi-transparent blue
		_unhighlight_participants()