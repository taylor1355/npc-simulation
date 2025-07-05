class_name InteractionFactory extends RefCounted

var source_component: EntityComponent  # The component that created this factory

func create_interaction(context: Dictionary = {}) -> Interaction:
	push_error("create_interaction must be implemented by subclass")
	return null

func get_interaction_name() -> String:
	push_error("get_interaction_name must be implemented by subclass") 
	return ""

func get_interaction_description() -> String:
	return ""

func can_create_for(entity: Node) -> bool:
	# Override to add preconditions
	return true

func is_multi_party() -> bool:
	return false

# Get metadata for this interaction type without creating an instance
func get_metadata() -> Dictionary:
	# Default implementation creates a temporary interaction for backward compatibility
	# Subclasses should override this to avoid creating temporary objects
	var temp_interaction = create_interaction({})
	if temp_interaction:
		return temp_interaction.to_dict()
	return {
		"name": get_interaction_name(),
		"description": get_interaction_description()
	}