class_name InteractionPanel extends BasePanel

## Base class for panels that display information about interactions (conversations, trades, etc).
## Panels are tied to a specific interaction ID rather than the focused entity.

var interaction_id: String = ""
var current_interaction: Interaction = null
var is_historical: bool = false  # Whether the interaction has ended

func _ready() -> void:
	# Listen for interaction events
	EventBus.event_dispatched.connect(_on_event)

func set_interaction_id(id: String) -> void:
	if interaction_id == id:
		return
		
	# Cleanup old interaction
	if current_interaction:
		_disconnect_from_interaction()
	
	# Setup new interaction
	interaction_id = id
	current_interaction = InteractionRegistry.get_interaction_by_id(id)
	
	if current_interaction:
		# Check if interaction is already ended based on participants
		# (empty participants typically means interaction has ended)
		is_historical = current_interaction.participants.is_empty()
		
		_connect_to_interaction()
		if is_historical:
			_on_interaction_became_historical()
		_update_display()

func _exit_tree() -> void:
	# Ensure we disconnect when panel is removed
	if current_interaction:
		_disconnect_from_interaction()
	if EventBus.event_dispatched.is_connected(_on_event):
		EventBus.event_dispatched.disconnect(_on_event)

func _on_event(event: Event) -> void:
	if event.event_type == Event.Type.INTERACTION_ENDED:
		var ended_event = event as InteractionEvents.InteractionEndedEvent
		if ended_event and ended_event.interaction_id == interaction_id:
			is_historical = true
			# Keep the interaction object - it has valuable historical data!
			_on_interaction_became_historical()
			_update_display()
			became_historical.emit()

# Override in subclasses to handle when interaction becomes historical
func _on_interaction_became_historical() -> void:
	pass

signal became_historical()

# Override these in subclasses to handle interaction-specific signals
func _connect_to_interaction() -> void:
	pass

func _disconnect_from_interaction() -> void:
	pass
