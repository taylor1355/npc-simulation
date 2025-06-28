class_name InteractionContext extends RefCounted

# Base class for interaction contexts that provide a unified interface
# for InteractingState regardless of single-party vs multi-party interactions

func get_display_name() -> String:
	return "Unknown"

func get_position() -> Vector2i:
	assert(false, "get_position() must be overridden in subclasses")
	return Vector2i.ZERO # Not actually used, just to satisfy the static type checker

func get_entity_type() -> String:
	return "unknown"

# Handle interaction cancellation in context-appropriate way
func handle_cancellation(_interaction: Interaction, _controller: NpcController) -> void:
	push_warning("Cancellation not implemented for this context type")

func get_context_data(interaction: Interaction, duration: float) -> Dictionary:
	return {
		"interaction_name": interaction.name,
		"duration": duration
	}

# Check whether this context can be used for the given interaction
func is_valid_for_interaction(_interaction: Interaction) -> bool:
	return true

func setup_completion_signals(_controller: NpcController, _interaction: Interaction) -> void:
	pass
