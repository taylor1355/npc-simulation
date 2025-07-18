extends BaseControllerState

class_name ControllerRequestingState

var interaction_request: InteractionBid
var target_controller: GamepieceController
var interaction_name: String
var timeout_timer: float = 0.0
var timeout_duration: float = 5.0  # Timeout after 5 seconds

func _init(controller_ref: NpcController) -> void:
	super(controller_ref)

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters)
	
	# Only handle interact_with action
	if action_name != "interact_with":
		_handle_invalid_action(action_name)
		return
	
	if not _validate_parameters(parameters):
		return
		
	if not _find_and_validate_target(parameters):
		return
		
	if not _create_interaction_bid(parameters):
		return
		
	_submit_bid()

func _handle_invalid_action(action_name: String) -> void:
	push_error("RequestingState only handles 'interact_with' action, got: %s" % action_name)
	controller.state_machine.change_state(ControllerIdleState.new(controller))

func _validate_parameters(parameters: Dictionary) -> bool:
	var target_name = parameters.get("entity_name", "")
	interaction_name = parameters.get("interaction_name", "")
	
	if target_name.is_empty() or interaction_name.is_empty():
		controller.event_log.append(NpcEvent.create_error_event("Missing target name or interaction name"))
		controller.state_machine.change_state(ControllerIdleState.new(controller))
		return false
		
	return true

func _find_and_validate_target(parameters: Dictionary) -> bool:
	var target_name = parameters.get("entity_name", "")
	
	# Find target (could be item or NPC)
	target_controller = _find_target(target_name)
	if not target_controller:
		controller.event_log.append(NpcEvent.create_error_event("Target not found: " + target_name))
		controller.state_machine.change_state(ControllerIdleState.new(controller))
		return false
	
	# Check if target has the requested interaction
	if not target_controller.interaction_factories.has(interaction_name):
		controller.event_log.append(NpcEvent.create_error_event(
			"Interaction '%s' not found on target '%s'" % [interaction_name, target_name]
		))
		controller.state_machine.change_state(ControllerIdleState.new(controller))
		return false
		
	return true

func _find_target(target_name: String) -> GamepieceController:
	# First try to find as item
	var item = controller._find_item_by_name(target_name)
	if item:
		return item
	
	# Then try to find as NPC
	var npc = controller._find_npc_by_name(target_name)
	if npc:
		return npc
		
	return null

func _create_interaction_bid(parameters: Dictionary) -> bool:
	# Get the interaction factory to check if it's multi-party
	var factory = target_controller.interaction_factories[interaction_name]
	
	if factory.is_multi_party():
		return _create_multi_party_bid(factory, parameters)
	else:
		return _create_single_party_bid()

func _create_single_party_bid() -> bool:
	# Create standard InteractionBid
	interaction_request = InteractionBid.new(
		interaction_name,
		InteractionBid.BidType.START,
		controller,
		target_controller
	)
	return true

func _create_multi_party_bid(factory: InteractionFactory, parameters: Dictionary) -> bool:
	# For multi-party interactions, we need additional participants
	var additional_targets = parameters.get("additional_targets", [])
	
	# Create the interaction instance
	var interaction = factory.create_interaction({"requester": controller, "target": target_controller})
	if not interaction:
		controller.event_log.append(NpcEvent.create_error_event("Failed to create interaction"))
		controller.state_machine.change_state(ControllerIdleState.new(controller))
		return false
	
	# Find additional participants
	var all_participants: Array[NpcController] = []
	for target_name in additional_targets:
		var participant = controller._find_npc_by_name(target_name)
		if participant:
			all_participants.append(participant)
		else:
			push_warning("Additional target not found: " + target_name)
	
	# If primary target is an NPC, include them
	if target_controller is NpcController:
		all_participants.insert(0, target_controller)
	
	# Create MultiPartyBid
	interaction_request = MultiPartyBid.new(
		interaction,
		InteractionBid.BidType.START,
		controller,
		all_participants
	)
	return true

func _submit_bid() -> void:
	controller.current_request = interaction_request
	
	# Connect to bid signals
	interaction_request.accepted.connect(on_interaction_accepted.bind(interaction_request), Node.CONNECT_ONE_SHOT)
	interaction_request.rejected.connect(on_interaction_rejected.bind(interaction_request), Node.CONNECT_ONE_SHOT)
	
	# Additional signals for multi-party bids
	if interaction_request is MultiPartyBid:
		var multi_bid = interaction_request as MultiPartyBid
		multi_bid.all_participants_accepted.connect(_on_all_participants_accepted)
		multi_bid.participant_rejected.connect(_on_participant_rejected)
		multi_bid.timed_out.connect(_on_timeout)
	
	# Log the request
	controller.event_log.append(NpcEvent.create_interaction_request_event(interaction_request))
	
	# Submit bid
	if interaction_request is MultiPartyBid:
		# Send to all invited participants
		var multi_bid = interaction_request as MultiPartyBid
		for participant in multi_bid.invited_participants:
			participant.handle_interaction_bid(interaction_request)
	else:
		# Send to single target
		target_controller.handle_interaction_bid.call_deferred(interaction_request)

func _on_all_participants_accepted() -> void:
	# All participants accepted - interaction will start
	pass

func _on_participant_rejected(participant: NpcController, reason: String) -> void:
	# One participant rejected - bid will be rejected
	pass

func _on_timeout() -> void:
	# MultiPartyBid timed out - return to idle
	controller.event_log.append(NpcEvent.create_error_event("Conversation request timed out"))
	controller.state_machine.change_state(ControllerIdleState.new(controller))
	controller.current_request = null
	
	# Trigger new decision after timeout
	controller.decide_behavior.call_deferred()

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	match action_name:
		"wait", "continue":
			# Valid while waiting for response
			return true
		_:
			return super.handle_action(action_name, parameters)

func _physics_process(delta: float) -> void:
	if not interaction_request:
		return
		
	# Check if target still exists
	if not is_instance_valid(target_controller) or target_controller.is_queued_for_deletion():
		_handle_target_destroyed()
		return
	
	# Update timeout for single-party bids
	if not interaction_request is MultiPartyBid:
		timeout_timer += delta
		if timeout_timer >= timeout_duration:
			_handle_timeout()

func _handle_target_destroyed() -> void:
	controller.event_log.append(NpcEvent.create_error_event("Target destroyed while requesting interaction"))
	controller.state_machine.change_state(ControllerIdleState.new(controller))
	controller.current_request = null
	controller.decide_behavior.call_deferred()

func _handle_timeout() -> void:
	controller.event_log.append(NpcEvent.create_error_event("Interaction request timed out"))
	controller.state_machine.change_state(ControllerIdleState.new(controller))
	controller.current_request = null
	controller.decide_behavior.call_deferred()

func get_context_data() -> Dictionary:
	var context = {
		"target_name": "",
		"interaction_name": interaction_name,
		"request_status": InteractionBid.BidStatus.keys()[interaction_request.status] if interaction_request else ""
	}
	
	# Safely check if target still exists
	if is_instance_valid(target_controller) and not target_controller.is_queued_for_deletion():
		context["target_name"] = target_controller.get_display_name()
		
		# Add position for items
		if target_controller is ItemController and target_controller._gamepiece:
			context["target_position"] = {
				"x": target_controller._gamepiece.cell.x,
				"y": target_controller._gamepiece.cell.y
			}
	
	# Add multi-party info
	if interaction_request is MultiPartyBid:
		var multi_bid = interaction_request as MultiPartyBid
		context["is_multi_party"] = true
		context["invited_count"] = multi_bid.invited_participants.size()
		context["accepted_count"] = multi_bid.accepted_participants.size()
	
	return context

func on_interaction_accepted(request: InteractionBid) -> void:
	if interaction_request != request:
		push_error("Accepted request doesn't match current request")
		return
	
	# For multi-party bids, the transition is handled by the bid itself
	# when it adds all participants (including the host)
	if request is MultiPartyBid:
		# Multi-party bid accepted - wait for the bid to coordinate all participants
		return
	
	# Get the interaction object
	var interaction_obj = request.interaction
	if not interaction_obj:
		push_error("Accepted request has no interaction object")
		return
		
	# Create appropriate context using interaction's factory method
	var context = interaction_obj.create_context(target_controller)
	if not context:
		push_error("Failed to create interaction context")
		return
	
	# Register with InteractionRegistry
	InteractionRegistry.register_interaction(interaction_obj, context)
	
	# Transition to interacting state
	var interacting_state = ControllerInteractingState.new(controller, interaction_obj, context)
	controller.state_machine.change_state(interacting_state)
	controller.current_interaction = interaction_obj
	
	# Set up interaction completion signals through the context
	context.setup_completion_signals(controller, interaction_obj)
	
	# Log interaction started
	controller.event_log.append(NpcEvent.create_interaction_update_event(
		request,
		NpcEvent.Type.INTERACTION_STARTED
	))

func on_interaction_rejected(request: InteractionBid, reason: String) -> void:
	# Log rejection
	controller.event_log.append(NpcEvent.create_interaction_rejected_event(request, reason))
	
	# Return to idle
	controller.state_machine.change_state(ControllerIdleState.new(controller))
	controller.current_request = null
	
	# Trigger new decision
	controller.decide_behavior()

func get_state_emoji() -> String:
	return "🤔"

func get_state_description(include_links: bool = false) -> String:
	if interaction_name and target_controller:
		var target_name = target_controller.get_display_name()
		if include_links:
			var link = UILink.entity(target_controller.get_entity_id(), target_name)
			target_name = link.to_bbcode()
		return "Requesting %s with %s" % [interaction_name, target_name]
	return "Requesting interaction..."
