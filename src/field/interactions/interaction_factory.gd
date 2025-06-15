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