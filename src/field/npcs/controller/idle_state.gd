extends BaseControllerState

class_name ControllerIdleState

func _init(controller_ref: NpcController) -> void:
	super(controller_ref)

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters)
	controller.destination = Vector2i() # Clear controller's general destination
	
	# If IdleState is entered as a result of an action it should handle (e.g. "continue" from another state)
	# it might do so here, or its handle_action will be called subsequently.
	# For now, the primary role of IdleState.enter() is to trigger a new decision if no specific action brought us here.
	if action_name == "": # Default entry, not from a specific action pass-through
		controller.decision_timer = controller.DECISION_INTERVAL # Trigger new decision
	# If an action *was* passed, handle_action will be called by the NpcController if this state was transitioned to
	# as part of _on_action_chosen. If transitioned to by another state directly, that state might call handle_action.
	# The current design of NpcController._on_action_chosen calls state_machine.handle_action.
	# If a state transitions *itself* (e.g. Wandering -> Idle on_gamepiece_arrived), then Idle.enter() is key.
	# If Wandering.handle_action("some_other_action") transitions to Idle, then Idle.handle_action("some_other_action")
	# would be called by NpcController.

	# Simplification: IdleState.enter always triggers a decision cycle unless an action is immediately handled.
	# The existing logic: controller.decision_timer = controller.DECISION_INTERVAL is good.
	# This ensures that returning to idle always re-evaluates.
	controller.decision_timer = controller.DECISION_INTERVAL

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	if controller.movement_locked and action_name in ["move_to", "wander"]:
		controller.event_log.append(NpcEvent.create_error_event("Cannot %s while movement is locked" % action_name))
		return true # Action is "handled" by logging an error

	match action_name:
		"move_to":
			# Transition to MovingState, passing the action
			controller.state_machine.change_state(ControllerMovingState.new(controller), action_name, parameters)
			return true
		"interact_with":
			# Transition to RequestingState, passing the action
			controller.state_machine.change_state(ControllerRequestingState.new(controller), action_name, parameters)
			return true
		"wander":
			controller.state_machine.change_state(ControllerWanderingState.new(controller), action_name, parameters)
			return true
		"wait":
			controller.state_machine.change_state(ControllerWaitingState.new(controller), action_name, parameters)
			return true
		"continue":
			# Continue is valid in idle - just means stay idle
			return true
		"start_conversation":
			# TODO: start_conversation should use the generic interact_with action
			# For now, log that it's not implemented
			controller.event_log.append(NpcEvent.create_error_event(
				"start_conversation is deprecated. Use interact_with with target NPCs instead."
			))
			return true
		_:
			return super.handle_action(action_name, parameters)

# _try_move_to, _try_start_interaction, _start_wandering are no longer needed here,
# as their logic is now implicitly handled by transitioning to the respective states
# and those states' enter() methods will use the passed action_name and parameters.

# _find_item_by_name is a utility. If NpcController doesn't have it, it should be added there.
# For now, assuming NpcController will have _find_item_by_name as per the design doc.
# func _find_item_by_name(item_name: String) -> ItemController:
	# var seen_items = controller._vision_manager.get_items_by_distance()
	# for item in seen_items:
		# if item.name == item_name:
			# return item
	# return null


func is_movement_allowed() -> bool:
	return not controller.movement_locked
