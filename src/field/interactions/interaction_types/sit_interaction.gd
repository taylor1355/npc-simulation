class_name SitInteraction extends Interaction

var sittable_component: SittableComponent

func _on_start(context: Dictionary) -> void:
	# Do sit-specific logic first
	if sittable_component:
		sittable_component._on_sit_start(self, context)
	
	# Call super last to dispatch event
	super._on_start(context)

func _on_end(context: Dictionary) -> void:
	# Do sit-specific cleanup first
	if sittable_component:
		sittable_component._on_sit_end(self, context)
	
	# Call super last to dispatch event
	super._on_end(context)

func get_interaction_emoji() -> String:
	return "🪑"