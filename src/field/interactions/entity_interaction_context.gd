class_name EntityInteractionContext extends InteractionContext

# Context for single-party interactions with items or NPCs
var target_controller: GamepieceController

func _init(_target_controller: GamepieceController):
	target_controller = _target_controller

func get_display_name() -> String:
	if target_controller:
		return target_controller.get_display_name()
	return "Unknown Entity"

func get_position() -> Vector2i:
	if target_controller:
		return target_controller.get_cell_position()
	return super.get_position()

func get_entity_type() -> String:
	if target_controller:
		return target_controller.get_entity_type()
	return "unknown"

func handle_cancellation(interaction: Interaction, controller: NpcController) -> void:
	if not target_controller:
		push_warning("No target controller for cancellation")
		return
	
	# Use existing bid system for entity interactions
	var request = InteractionBid.new(
		interaction.name,
		InteractionBid.BidType.CANCEL,
		controller,
		target_controller
	)
	
	# Log the cancel request
	controller.event_log.append(NpcEvent.create_interaction_request_event(request))
	
	# Set up response handlers
	request.accepted.connect(
		func():
			controller.event_log.append(NpcEvent.create_interaction_update_event(
				request,
				NpcEvent.Type.INTERACTION_CANCELED
			))
			controller.current_request = null
			controller.current_interaction = null
			controller.state_machine.change_state(ControllerIdleState.new(controller))
	)
	
	request.rejected.connect(
		func(reason: String):
			controller.event_log.append(NpcEvent.create_interaction_rejected_event(request, reason))
	)
	
	# Submit the cancellation request
	target_controller.handle_interaction_bid(request)

func get_context_data(interaction: Interaction, duration: float) -> Dictionary:
	var context = super.get_context_data(interaction, duration)
	
	if target_controller:
		context["entity_name"] = target_controller.get_display_name()
		context["entity_type"] = target_controller.get_entity_type()
		
		var position = target_controller.get_cell_position()
		if position != null:
			context["entity_position"] = {
				"x": position.x,
				"y": position.y
			}
	
	return context

func is_valid_for_interaction(interaction: Interaction) -> bool:
	return target_controller != null and interaction.max_participants == 1

func setup_completion_signals(controller: NpcController, _interaction: Interaction) -> void:
	if target_controller:
		target_controller.interaction_finished.connect(
			controller._on_interaction_finished,
			Node.CONNECT_ONE_SHOT
		)
