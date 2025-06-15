extends BaseControllerState

class_name ControllerInteractingState

var interaction: Interaction
var target_controller: GamepieceController
var started_at: float

func _init(controller_ref: NpcController, _interaction: Interaction, _target_controller: GamepieceController) -> void:
	super(controller_ref)
	interaction = _interaction
	target_controller = _target_controller

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters)
	# interaction and target_controller must be set by RequestingState before transition.
	assert(interaction != null, "InteractingState requires interaction to be set")
	assert(target_controller != null, "InteractingState requires target_controller to be set")
	started_at = Time.get_unix_time_from_system()
	
	# Listen for interaction observations directed at this NPC
	EventBus.event_dispatched.connect(_on_event_dispatched)

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	match action_name:
		"cancel_interaction":
			_try_cancel_interaction()
			return true
		"continue":
			return true
		"act_in_interaction":
			_handle_act_in_interaction(parameters)
			return true
		_:
			return super.handle_action(action_name, parameters)

func _try_cancel_interaction() -> void:
	if not interaction or not controller.current_request:
		return
	
	# For multi-party interactions, we need to handle cancellation differently
	if interaction is StreamingInteraction:
		# For streaming interactions, just leave the interaction
		var streaming = interaction as StreamingInteraction
		streaming.remove_participant(controller)
		
		# Log cancellation
		controller.event_log.append(NpcEvent.create_interaction_update_event(
			controller.current_request,
			NpcEvent.Type.INTERACTION_CANCELED
		))
		
		# Clear state and return to idle
		controller.current_request = null
		controller.current_interaction = null
		controller.state_machine.change_state(ControllerIdleState.new(controller))
		return
	
	# For entity interactions, use the cancel bid system
	# Create cancel bid with interaction name
	var request = InteractionBid.new(
		interaction.name,
		InteractionBid.BidType.CANCEL,
		controller,
		target_controller
	)
	
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
	
	target_controller.handle_interaction_bid(request)

func on_interaction_finished(interaction_name: String, npc: NpcController, payload: Dictionary) -> void:
	# Log interaction finished event
	controller.event_log.append(NpcEvent.create_interaction_update_event(
		controller.current_request,
		NpcEvent.Type.INTERACTION_FINISHED
	))
	
	interaction._on_end(payload)
	
	# Clear interaction state
	controller.current_interaction = null # NpcController manages this
	controller.current_request = null # NpcController manages this
	
	# Return to idle
	controller.state_machine.change_state(ControllerIdleState.new(controller))
	
	# Trigger new decision (IdleState.enter will handle this)
	# controller.decide_behavior() # Removed as IdleState.enter will trigger it

func exit() -> void:
	if EventBus.event_dispatched.is_connected(_on_event_dispatched):
		EventBus.event_dispatched.disconnect(_on_event_dispatched)
	super.exit()

func _handle_act_in_interaction(parameters: Dictionary) -> void:
	if not interaction:
		return
		
	interaction.handle_act_in_interaction(controller, parameters)

func _on_event_dispatched(event: Event) -> void:
	if not event.is_type(Event.Type.NPC_INTERACTION_OBSERVATION):
		return
		
	var observation_event = event as NpcEvents.InteractionObservationEvent
	if observation_event.npc != controller._gamepiece:
		return
		
	var interaction_observation_event = NpcEvent.create_interaction_observation_event(
		observation_event.observation.get("interaction_name", ""),
		observation_event.observation
	)
	controller.event_log.append(interaction_observation_event)

func get_context_data() -> Dictionary:
	var cell_pos = target_controller.get_cell_position()
	return {
		"interaction_name": interaction.name,
		"entity_name": target_controller.get_display_name(),
		"entity_position": {
			"x": cell_pos.x, 
			"y": cell_pos.y
		},
		"entity_type": target_controller.get_entity_type(),
		"duration": Time.get_unix_time_from_system() - started_at
	}
