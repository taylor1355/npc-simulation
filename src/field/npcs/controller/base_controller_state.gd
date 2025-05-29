class_name BaseControllerState extends RefCounted

var controller: NpcController  # Reference to the controller
var state_name: String  # Name of the state for logging

func _init(controller_ref: NpcController) -> void:
	controller = controller_ref
	state_name = get_script().resource_path.get_file().trim_suffix("_state.gd")

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	# Default enter logic, can be overridden.
	# Subclasses will use action_name and parameters if provided.
	pass

func exit() -> void:
	# Override in subclasses for state exit logic
	pass

# Handle actions from the backend - return true if handled
func handle_action(action_name: String, parameters: Dictionary) -> bool:
	# Default implementation logs unhandled actions
	controller.event_log.append(NpcEvent.create_error_event(
		"Action '%s' not valid in %s state" % [action_name, state_name]
	))
	return false

# Get state context data for backend observation
func get_context_data() -> Dictionary:
	return {}

# Called when gamepiece arrives at destination
func on_gamepiece_arrived() -> void:
	pass

# Check if movement is allowed in this state
func is_movement_allowed() -> bool:
	return false

# Called when an interaction request is accepted
func on_interaction_accepted(request: InteractionRequest) -> void:
	controller.event_log.append(NpcEvent.create_error_event(
		"Interaction accepted in unexpected state: %s" % state_name
	))

# Called when an interaction request is rejected
func on_interaction_rejected(request: InteractionRequest, reason: String) -> void:
	controller.event_log.append(NpcEvent.create_error_event(
		"Interaction rejected in unexpected state: %s" % state_name
	))

# Called when an interaction finishes
func on_interaction_finished(interaction_name: String, npc: NpcController, payload: Dictionary) -> void:
	pass
