class_name InteractionContext extends RefCounted

# Base class for interaction contexts that provide a unified interface
# for InteractingState regardless of single-party vs multi-party interactions

# Get display name for UI purposes
func get_display_name() -> String:
	return "Unknown"

# Get position for context data (null means no specific position)
func get_position() -> Vector2i:
	return null

# Get entity type for context data
func get_entity_type() -> String:
	return "unknown"

# Handle interaction cancellation in context-appropriate way
func handle_cancellation(interaction: Interaction, controller: NpcController) -> void:
	push_warning("Cancellation not implemented for this context type")

# Get context data for backend observations
func get_context_data(interaction: Interaction, duration: float) -> Dictionary:
	return {
		"interaction_name": interaction.name,
		"duration": duration
	}

# Check if this context can be used for the given interaction
func is_valid_for_interaction(interaction: Interaction) -> bool:
	return true

# Set up interaction completion signal connections
# Override in subclasses to connect to appropriate completion signals
func setup_completion_signals(controller: NpcController, interaction: Interaction) -> void:
	pass