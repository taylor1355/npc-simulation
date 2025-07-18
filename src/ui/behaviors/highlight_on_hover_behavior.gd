class_name HighlightOnHoverBehavior extends BaseUIBehavior

## Highlights entities on hover.
## Can highlight the hovered entity itself or entities it's interacting with.

enum HighlightTarget {
	SELF,         # Highlight the hovered entity
	INTERACTION   # Highlight entities the hovered entity is interacting with
}

# Configuration
var highlight_target: HighlightTarget = HighlightTarget.SELF
var highlight_color: Color = Color(1.2, 1.2, 1.2)
var highlight_priority: int = HighlightManager.Priority.HOVER

# Source ID for highlight manager
var source_id: String = ""

func _on_configured() -> void:
	# Parse highlight target from config
	var target_str = config.get("highlight_target", "self")
	match target_str.to_lower():
		"self":
			highlight_target = HighlightTarget.SELF
		"interaction":
			highlight_target = HighlightTarget.INTERACTION
		_:
			push_error("Invalid highlight_target: %s. Using 'self'" % target_str)
			highlight_target = HighlightTarget.SELF
	
	highlight_color = config.get("highlight_color", Color(1.2, 1.2, 1.2))
	highlight_priority = config.get("highlight_priority", HighlightManager.Priority.HOVER)
	
	# Generate unique source ID based on configuration
	source_id = "hover_%s_%d" % [HighlightTarget.keys()[highlight_target].to_lower(), get_instance_id()]

func on_hover_start(gamepiece: Gamepiece) -> void:
	var entity_id = gamepiece.entity_id
	
	match highlight_target:
		HighlightTarget.SELF:
			# Highlight the hovered entity itself
			HighlightManager.highlight(entity_id, source_id, highlight_color, highlight_priority)
		
		HighlightTarget.INTERACTION:
			# Highlight entities the hovered entity is interacting with
			var controller = gamepiece.get_controller()
			if controller:
				var interaction = controller.get_current_interaction()
				if interaction:
					HighlightManager.highlight_interaction(interaction.id, source_id, highlight_color, highlight_priority)

func on_hover_end(gamepiece: Gamepiece) -> void:
	var entity_id = gamepiece.entity_id
	
	match highlight_target:
		HighlightTarget.SELF:
			# Remove highlight from the hovered entity
			HighlightManager.unhighlight(entity_id, source_id)
		
		HighlightTarget.INTERACTION:
			# Remove highlights from interacting entities
			var controller = gamepiece.get_controller()
			if controller:
				var interaction = controller.get_current_interaction()
				if interaction:
					HighlightManager.unhighlight_interaction(interaction.id, source_id)
