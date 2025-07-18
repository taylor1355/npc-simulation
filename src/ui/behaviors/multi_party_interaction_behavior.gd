class_name MultiPartyInteractionBehavior extends BaseUIBehavior

## Manages visual lines for multi-party interactions.
## A persistent singleton that handles all interactions of configured types.

func _on_configured() -> void:
	# Listen for highlight events once
	var tracker = UIRegistry.get_state_tracker()
	tracker.interaction_highlighted.connect(_on_interaction_highlighted)
	tracker.interaction_unhighlighted.connect(_on_interaction_unhighlighted)

func on_interaction_started(interaction_id: String) -> void:
	print("MultiPartyInteractionBehavior.on_interaction_started(%s)" % interaction_id)
	# Add this interaction to the line manager
	InteractionLineManager.add_interaction(interaction_id)

func on_interaction_ended(interaction_id: String) -> void:
	print("MultiPartyInteractionBehavior.on_interaction_ended(%s)" % interaction_id)
	# Remove from line manager
	InteractionLineManager.remove_interaction(interaction_id)
	print("  -> Called InteractionLineManager.remove_interaction")

func _on_interaction_highlighted(interaction_id: String) -> void:
	# Pass through to manager - it will handle checking if it's tracking this interaction
	InteractionLineManager.highlight_interaction(interaction_id)

func _on_interaction_unhighlighted(interaction_id: String) -> void:
	# Pass through to manager - it will handle checking if it's tracking this interaction
	InteractionLineManager.unhighlight_interaction(interaction_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Clean up connections
		var tracker = UIRegistry.get_state_tracker()
		if tracker.interaction_highlighted.is_connected(_on_interaction_highlighted):
			tracker.interaction_highlighted.disconnect(_on_interaction_highlighted)
		if tracker.interaction_unhighlighted.is_connected(_on_interaction_unhighlighted):
			tracker.interaction_unhighlighted.disconnect(_on_interaction_unhighlighted)
