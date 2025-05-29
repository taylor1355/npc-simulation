extends BaseControllerState

class_name ControllerInteractingState

var interaction: Interaction
var item_controller: ItemController
var started_at: float

func _init(controller_ref: NpcController) -> void:
	super(controller_ref)

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters)
	# interaction and item_controller are set by RequestingState before transition.
	# This state is not typically entered directly via an action that its 'enter' method needs to parse.
	started_at = Time.get_unix_time_from_system()

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	match action_name:
		"cancel_interaction":
			_try_cancel_interaction()
			return true
		"continue":
			# Valid - continue interacting
			return true
		_:
			return super.handle_action(action_name, parameters)

func _try_cancel_interaction() -> void:
	if not interaction or not controller.current_request:
		return
	
	var request = interaction.create_cancel_request(controller)
	request.item_controller = controller.current_request.item_controller
	
	# Log the cancel request
	controller.event_log.append(NpcEvent.create_interaction_request_event(request))
	
	request.accepted.connect(
		func():
			# Log interaction canceled
			controller.event_log.append(NpcEvent.create_interaction_update_event(
				request,
				NpcEvent.Type.INTERACTION_CANCELED
			))
			controller.current_request = null # NpcController manages this
			controller.current_interaction = null # NpcController manages this
			controller.state_machine.change_state(ControllerIdleState.new(controller))
	)
	
	request.rejected.connect(
		func(reason: String):
			# Log the rejected cancel with reason
			controller.event_log.append(NpcEvent.create_interaction_rejected_event(request, reason))
	)
	
	interaction.cancel_request.emit(request)

func on_interaction_finished(interaction_name: String, npc: NpcController, payload: Dictionary) -> void:
	# Log interaction finished event
	controller.event_log.append(NpcEvent.create_interaction_update_event(
		controller.current_request,
		NpcEvent.Type.INTERACTION_FINISHED
	))
	
	# Clear interaction state
	controller.current_interaction = null # NpcController manages this
	controller.current_request = null # NpcController manages this
	
	# Return to idle
	controller.state_machine.change_state(ControllerIdleState.new(controller))
	
	# Trigger new decision (IdleState.enter will handle this)
	# controller.decide_behavior() # Removed as IdleState.enter will trigger it

func get_context_data() -> Dictionary:
	return {
		"interaction_name": interaction.name if interaction else "",
		"item_name": item_controller.name if item_controller else "",
		"item_position": {"x": item_controller._gamepiece.cell.x, "y": item_controller._gamepiece.cell.y} if item_controller else {},
		"duration": Time.get_unix_time_from_system() - started_at
	}
