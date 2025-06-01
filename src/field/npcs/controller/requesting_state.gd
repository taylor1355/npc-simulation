extends BaseControllerState

class_name ControllerRequestingState

var interaction_request: InteractionBid
var target_item: ItemController
var interaction_name: String

func _init(controller_ref: NpcController) -> void:
	super(controller_ref)

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters)
	if action_name == "interact_with":
		var item_name = parameters.item_name
		var p_interaction_name = parameters.interaction_name # Renamed to avoid conflict with var
		
		# Assuming controller._find_item_by_name exists
		self.target_item = controller._find_item_by_name(item_name)
		self.interaction_name = p_interaction_name

		if not self.target_item:
			controller.event_log.append(NpcEvent.create_error_event("Item not found: " + item_name))
			controller.state_machine.change_state(ControllerIdleState.new(controller)) # Go back to idle
			return
		
		if not self.target_item.interactions.has(self.interaction_name):
			controller.event_log.append(NpcEvent.create_error_event(
				"Interaction '%s' not found on item '%s'" % [self.interaction_name, item_name]
			))
			controller.state_machine.change_state(ControllerIdleState.new(controller)) # Go back to idle
			return

		var interaction_obj = self.target_item.interactions[self.interaction_name] # Renamed
		self.interaction_request = interaction_obj.create_start_bid(controller)
		
		controller.current_request = self.interaction_request # NpcController tracks this
		
		self.interaction_request.accepted.connect(controller._on_interaction_accepted.bind(self.interaction_request), Node.CONNECT_ONE_SHOT)
		self.interaction_request.rejected.connect(controller._on_interaction_rejected.bind(self.interaction_request), Node.CONNECT_ONE_SHOT)
		
		controller.event_log.append(NpcEvent.create_interaction_request_event(self.interaction_request))
		self.target_item.request_interaction.call_deferred(self.interaction_request)
	else:
		push_error("RequestingState entered without 'interact_with' action or invalid parameters.")
		controller.state_machine.change_state(ControllerIdleState.new(controller))

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	match action_name:
		"wait", "continue":
			# Valid while waiting for response
			return true
		_:
			return super.handle_action(action_name, parameters)

func get_context_data() -> Dictionary:
	return {
		"item_name": target_item.name if target_item else "",
		"item_position": {"x": target_item._gamepiece.cell.x, "y": target_item._gamepiece.cell.y} if target_item else {},
		"interaction_name": interaction_name,
		"request_type": InteractionBid.BidType.keys()[interaction_request.bid_type] if interaction_request else ""
	}

func on_interaction_accepted(request: InteractionBid) -> void:
	if interaction_request != request:
		push_error("Accepted request doesn't match current request")
		# Potentially go to Idle, but for now, just log and return if it's a different request.
		# This situation implies a logic error elsewhere or a race condition.
		return
	
	# Transition to interacting
	var interaction_obj = target_item.interactions[interaction_name] # Renamed for clarity
	var interacting_state = ControllerInteractingState.new(controller)
	# Pass action and params if InteractingState.enter needs them, though likely not for this transition
	# For now, InteractingState.enter() doesn't use specific action/params for this transition path
	controller.state_machine.change_state(interacting_state) 
	controller.current_interaction = interaction_obj # NpcController tracks this
	
	# Set up the interacting state directly with necessary data
	# This was in the design doc for RequestingState.on_interaction_accepted but makes more sense
	# if InteractingState.enter takes these. For now, direct assignment as per original code.
	interacting_state.interaction = interaction_obj
	interacting_state.item_controller = target_item

	# Connect to interaction finished
	target_item.interaction_finished.connect(
		controller._on_interaction_finished,
		Node.CONNECT_ONE_SHOT
	)
	
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
	controller.current_request = null # NpcController clears this
	
	# Trigger new decision (IdleState.enter will handle this)
	controller.decide_behavior()
