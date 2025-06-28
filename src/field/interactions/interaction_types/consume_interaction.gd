class_name ConsumeInteraction extends Interaction

var consumable_component: ConsumableComponent

func _on_start(context: Dictionary) -> void:
	# Do consume-specific logic first
	if consumable_component:
		consumable_component._on_consume_start(self, context)
	
	# Call super last to dispatch event
	super._on_start(context)

func _on_end(context: Dictionary) -> void:
	# Do consume-specific cleanup first
	if consumable_component:
		consumable_component._on_consume_end(self, context)
	
	# Call super last to dispatch event
	super._on_end(context)

func get_interaction_emoji() -> String:
	return "🍽️"