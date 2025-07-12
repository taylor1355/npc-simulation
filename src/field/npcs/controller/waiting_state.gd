extends BaseControllerState

class_name ControllerWaitingState

var started_at: float
var reason: String = ""

func _init(controller_ref: NpcController, p_reason: String = "") -> void: # p_reason in _init is not used if enter sets it
	super(controller_ref)
	# reason = p_reason # Reason should be set by parameters in enter, or via a property if set before transition

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters)
	if action_name == "wait" or action_name == "": # "" for initial entry or direct transition
		self.started_at = Time.get_unix_time_from_system()
		if parameters.has("reason"):
			self.reason = parameters.reason
		# If reason was set as a property before transition and no "reason" in params, it would persist.
		# else: self.reason remains as it was (e.g. from _init or previous set)
	# else: if entered with another action, it's likely an error or mis-transition

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	if controller.movement_locked and action_name in ["move_to", "wander"]:
		controller.event_log.append(NpcEvent.create_error_event("Cannot %s while movement is locked" % action_name))
		return true

	match action_name:
		"continue", "wait": # "wait" action could also refresh the reason if params are passed
			if parameters.has("reason") and action_name == "wait": # Refresh reason if "wait" action provides it
				self.reason = parameters.reason
				self.started_at = Time.get_unix_time_from_system() # Reset timer if re-waiting with new reason
			return true # Continue waiting
		"move_to":
			controller.state_machine.change_state(ControllerMovingState.new(controller), action_name, parameters)
			return true
		"interact_with":
			controller.state_machine.change_state(ControllerRequestingState.new(controller), action_name, parameters)
			return true
		"wander":
			controller.state_machine.change_state(ControllerWanderingState.new(controller), action_name, parameters)
			return true
		_:
			return super.handle_action(action_name, parameters)

func get_context_data() -> Dictionary:
	return {
		"duration": Time.get_unix_time_from_system() - started_at,
		"reason": reason
	}

func get_state_emoji() -> String:
	return "⏳"

func get_state_description(include_links: bool = false) -> String:
	return "Waiting..."
