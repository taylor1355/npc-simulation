extends Node

## Centralized manager for all entity highlighting.

enum Priority {
	ERROR = 0,  # Highest priority
	INTERACTION_TARGET = 10,
	SELECTION = 20,
	HOVER = 100  # Lowest priority
}

# Structure: entity_id -> {source_id -> {color, priority}}
var _highlights: Dictionary[String, Dictionary] = {}

# Track which entities were highlighted for each interaction by each source
# Structure: interaction_id -> {source_id -> [entity_ids]}
var _interaction_highlights: Dictionary[String, Dictionary] = {}

## Apply a highlight to an entity
func highlight(entity_id: String, source: String, color: Color, priority: int = Priority.HOVER) -> void:
	if not _highlights.has(entity_id):
		_highlights[entity_id] = {}
	
	_highlights[entity_id][source] = {
		"color": color,
		"priority": priority
	}
	
	_update_entity_visual(entity_id)

## Remove a highlight from an entity
func unhighlight(entity_id: String, source: String) -> void:
	if not _highlights.has(entity_id):
		return
	
	_highlights[entity_id].erase(source)
	
	if _highlights[entity_id].is_empty():
		_highlights.erase(entity_id)
	
	_update_entity_visual(entity_id)

## Clear all highlights for an entity
func clear_entity(entity_id: String) -> void:
	if _highlights.has(entity_id):
		_highlights.erase(entity_id)
		_update_entity_visual(entity_id)

## Update the visual appearance of an entity based on active highlights
func _update_entity_visual(entity_id: String) -> void:
	var controller = EntityRegistry.get_entity(entity_id)
	if not controller:
		return
	
	var gamepiece = controller.get_gamepiece()
	if not gamepiece:
		return
	
	# Find the highest priority highlight (lower number = higher priority)
	var highest_priority_color = Color.WHITE
	var highest_priority = INF
	
	if _highlights.has(entity_id):
		for source in _highlights[entity_id]:
			var data = _highlights[entity_id][source]
			if data.priority < highest_priority:
				highest_priority = data.priority
				highest_priority_color = data.color
	
	SpriteUtils.apply_color_to_sprites(gamepiece, highest_priority_color)

func _ready() -> void:
	# Listen for entity destruction and interaction events
	EventBus.event_dispatched.connect(_on_event_dispatched)

func _on_event_dispatched(event: Event) -> void:
	match event.event_type:
		Event.Type.GAMEPIECE_DESTROYED:
			var destroyed_event = event as GamepieceEvents.DestroyedEvent
			if destroyed_event and destroyed_event.gamepiece:
				clear_entity(destroyed_event.gamepiece.entity_id)
		Event.Type.INTERACTION_ENDED:
			var interaction_event = event as InteractionEvents.InteractionEvent
			if interaction_event:
				_cleanup_interaction_highlights(interaction_event.interaction_id)

func highlight_interaction(interaction_id: String, source: String, color: Color, priority: int = Priority.INTERACTION_TARGET) -> void:
	var interaction = InteractionRegistry.get_interaction(interaction_id)
	if not interaction:
		return
	
	# Track which entities we're highlighting for this interaction
	if not _interaction_highlights.has(interaction_id):
		_interaction_highlights[interaction_id] = {}
	if not _interaction_highlights[interaction_id].has(source):
		_interaction_highlights[interaction_id][source] = []
	
	var highlighted_entities = []
	
	# Highlight the host
	var context = InteractionRegistry.get_context_for_interaction(interaction_id)
	if context and context.host:
		var host_id = context.host.get_entity_id()
		highlight(host_id, source, color, priority)
		highlighted_entities.append(host_id)
	
	# Highlight all participants
	for entity_id in interaction.get_entity_ids():
		highlight(entity_id, source, color, priority)
		if entity_id not in highlighted_entities:
			highlighted_entities.append(entity_id)
	
	# Store which entities were highlighted
	_interaction_highlights[interaction_id][source] = highlighted_entities
	
	# Also highlight interaction lines
	InteractionLineManager.highlight_interaction(interaction_id)

func unhighlight_interaction(interaction_id: String, source: String) -> void:
	# Use tracked data instead of querying the interaction (which might be gone)
	if _interaction_highlights.has(interaction_id) and _interaction_highlights[interaction_id].has(source):
		# Unhighlight all entities that were highlighted for this interaction by this source
		for entity_id in _interaction_highlights[interaction_id][source]:
			unhighlight(entity_id, source)
		
		# Clean up the tracking
		_interaction_highlights[interaction_id].erase(source)
		if _interaction_highlights[interaction_id].is_empty():
			_interaction_highlights.erase(interaction_id)
	
	# Also unhighlight interaction lines
	InteractionLineManager.unhighlight_interaction(interaction_id)

func _cleanup_interaction_highlights(interaction_id: String) -> void:
	# When an interaction ends, clean up ALL highlights for that interaction from ALL sources
	if not _interaction_highlights.has(interaction_id):
		return
	
	# Unhighlight from all sources
	for source in _interaction_highlights[interaction_id]:
		for entity_id in _interaction_highlights[interaction_id][source]:
			unhighlight(entity_id, source)
	
	# Remove the interaction from tracking
	_interaction_highlights.erase(interaction_id)
