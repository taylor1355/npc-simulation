class_name ConversableComponent extends NpcComponent

# Inner factory class for conversation interactions
class ConversationInteractionFactory extends InteractionFactory:
	var max_distance: float = 5.0
	
	func get_interaction_name() -> String:
		return "conversation"
	
	func get_interaction_description() -> String:
		return "Have a conversation"
	
	func is_multi_party() -> bool:
		return true
	
	func create_interaction(context: Dictionary = {}) -> Interaction:
		var interaction = ConversationInteraction.new()
		interaction.max_participants = 10
		interaction.min_participants = 2
		
		return interaction

# Property configuration
func _init():
	PROPERTY_SPECS["max_conversation_distance"] = PropertySpec.new(
		"max_conversation_distance",
		TypeConverters.PropertyType.FLOAT,
		5.0,
		"Maximum distance for conversation participation"
	)

# Configured properties
var max_conversation_distance: float = 5.0

func _component_ready() -> void:
	# TODO: Could validate conversation settings here if needed
	pass

func _create_interaction_factories() -> Array[InteractionFactory]:
	var factory = ConversationInteractionFactory.new()
	factory.source_component = self
	factory.max_distance = max_conversation_distance
	return [factory]
