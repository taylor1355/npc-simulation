extends BaseControllerState

class_name ControllerWanderingState

var started_at: float

func _init(controller_ref: NpcController) -> void:
	super(controller_ref)

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters)
	# Only set started_at and new_destination if this state is entered for "wander"
	# or if it's entered without a specific action (e.g. initial state, though unlikely for Wandering)
	if action_name == "wander" or action_name == "": 
		self.started_at = Time.get_unix_time_from_system()
		# It's important NpcController's set_new_destination is called for random destination
		controller.set_new_destination() 
	# If entered via a different action (e.g. from Idle handling "wander"),
	# the action_name "wander" would trigger the above.
	# If somehow transitioned here with e.g. "move_to", that's a logic error elsewhere.

func exit() -> void:
	pass

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	if controller.movement_locked and action_name in ["move_to", "wander"]: # "wander" itself might be an action to start wandering
		controller.event_log.append(NpcEvent.create_error_event("Cannot %s while movement is locked" % action_name))
		return true

	match action_name:
		"continue":
			# Continue wandering is valid
			return true
		"move_to":
			controller.state_machine.change_state(ControllerMovingState.new(controller), action_name, parameters)
			return true
		"interact_with":
			controller.state_machine.change_state(ControllerRequestingState.new(controller), action_name, parameters)
			return true
		"wait":
			controller.state_machine.change_state(ControllerWaitingState.new(controller), action_name, parameters)
			return true
		_:
			return super.handle_action(action_name, parameters)

func on_gamepiece_arrived() -> void:
	# Finished a wander segment, go to Idle to decide next general action
	controller.state_machine.change_state(ControllerIdleState.new(controller))
	# IdleState.enter() will trigger controller.decide_behavior()

func get_context_data() -> Dictionary:
	return {
		"duration": Time.get_unix_time_from_system() - started_at
	}

func is_movement_allowed() -> bool:
	return not controller.movement_locked
