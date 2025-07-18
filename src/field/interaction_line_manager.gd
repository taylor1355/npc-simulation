extends Node2D

## Singleton that manages drawing lines between interaction participants.
## Coordinated by behaviors rather than listening to events directly.

# Line configuration structure
class LineConfig extends RefCounted:
	var color: Color = Color(0.5, 0.5, 1.0, 0.5)
	var width: float = 2.0
	var highlighted_color: Color = Color(1.0, 1.0, 0.5, 0.6)
	var highlighted_width: float = 2.5

# Interaction data structure
class InteractionData extends RefCounted:
	var interaction: Interaction
	var interaction_type: String
	var highlighted: bool = false

# Line configurations by interaction type
var _line_configs: Dictionary[String, LineConfig] = {}

# Active interactions to draw
var _active_interactions: Dictionary[String, InteractionData] = {}

func _ready() -> void:
	z_index = 10
	set_process(true)
	
	# Set up default config for conversations
	var conversation_config = LineConfig.new()
	_line_configs["conversation"] = conversation_config

func add_interaction(interaction_id: String) -> void:
	var interaction = InteractionRegistry.get_interaction(interaction_id)
	if not interaction:
		push_error("Interaction with id %s not found in registry" % interaction_id)
		return
	
	# Don't add if already tracking
	if _active_interactions.has(interaction_id):
		return
	
	var data = InteractionData.new()
	data.interaction = interaction
	data.interaction_type = interaction.name
	data.highlighted = false
	
	_active_interactions[interaction_id] = data
	queue_redraw()

func remove_interaction(interaction_id: String) -> void:
	_active_interactions.erase(interaction_id)
	queue_redraw()

func highlight_interaction(interaction_id: String) -> void:
	if not _active_interactions.has(interaction_id):
		add_interaction(interaction_id)
	
	_active_interactions[interaction_id].highlighted = true
	queue_redraw()

func unhighlight_interaction(interaction_id: String) -> void:
	if _active_interactions.has(interaction_id):
		_active_interactions[interaction_id].highlighted = false
		queue_redraw()

func has_interaction(interaction_id: String) -> bool:
	return _active_interactions.has(interaction_id)

func set_line_config(interaction_type: String, config: LineConfig) -> void:
	_line_configs[interaction_type] = config
	queue_redraw()

func _draw() -> void:
	for interaction_id in _active_interactions:
		var data = _active_interactions[interaction_id]
		var interaction = data.interaction
		
		if not is_instance_valid(interaction):
			continue
		
		var config = _line_configs.get(data.interaction_type)
		if not config:
			push_error("No config set for interaction_type %s" % data.interaction_type)
		
		# Collect participant positions
		var points = PackedVector2Array()
		for participant in interaction.participants:
			if is_instance_valid(participant) and participant.get_gamepiece():
				var pos = participant.get_gamepiece().global_position
				points.append(to_local(pos))
		
		# Draw line if we have at least 2 participants
		if points.size() >= 2:
			# Use highlighted or regular style - only one line per interaction
			var color = config.highlighted_color if data.highlighted else config.color
			var width = config.highlighted_width if data.highlighted else config.width
			draw_polyline(points, color, width, true)
