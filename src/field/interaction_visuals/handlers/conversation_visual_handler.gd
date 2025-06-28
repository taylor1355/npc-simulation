class_name ConversationVisualHandler extends BaseVisualHandler

var line: Line2D

func _on_setup() -> void:
	# Create line
	line = Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.5, 0.5, 1.0, 0.5)  # Semi-transparent blue
	line.z_index = -1  # Draw behind NPCs
	
	# TODO: Add dotted texture for a more subtle look
	# var texture = preload("res://assets/ui/dotted_line.png")
	# line.texture = texture
	# line.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	add_child(line)

func _process(_delta: float) -> void:
	if participants.is_empty():
		return
		
	# Update line to connect all participants
	var points = PackedVector2Array()
	for npc in participants:
		if is_instance_valid(npc) and npc._gamepiece:
			var pos = npc._gamepiece.global_position
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