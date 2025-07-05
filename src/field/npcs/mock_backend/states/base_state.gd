class_name BaseAgentState

var agent  # Reference to the agent this state belongs to
var state_name: String  # Name of the state for logging
var expected_controller_state: String = ""  # Expected controller state for validation

func _init(agent_ref):
	agent = agent_ref
	state_name = get_script().resource_path.get_file().trim_suffix("State.gd")

func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func update(_seen_items: Array, _needs: Dictionary) -> Action:
	# Validate we're in the correct state before processing
	if not _is_state_valid():
		return Action.continue_action()  # Don't process if state is out of sync
	
	return _do_update(_seen_items, _needs)

func _do_update(_seen_items: Array, _needs: Dictionary) -> Action:
	return Action.wait()  # Base state does nothing

func _is_state_valid() -> bool:
	"""Check if agent state matches controller state"""
	if expected_controller_state.is_empty():
		return true  # No validation needed
	
	if not agent.current_observation:
		return true  # No observation to validate against
	
	var status_obs = _get_status_observation()
	if not status_obs:
		return true  # No status to validate against
	
	var controller_state = status_obs.controller_state.get("state_enum", "")
	if controller_state.is_empty():
		return true  # No controller state to validate against
	
	# Check if controller state matches expected state
	if controller_state != expected_controller_state:
		push_error("[%s] State mismatch: Agent in %s but controller in %s - skipping update" % 
			[agent.id, state_name, controller_state])
		return false
	
	return true

func _get_status_observation() -> StatusObservation:
	"""Helper to extract status observation from current observation"""
	if agent.current_observation is StatusObservation:
		return agent.current_observation
	elif agent.current_observation is CompositeObservation:
		return agent.current_observation.find_observation(StatusObservation)
	return null
	
func should_check_needs() -> bool:
	return true  # Most states should check needs

func handle_incoming_interaction_bid(bid_observation: InteractionRequestObservation) -> bool:
	"""Handle incoming interaction bids. Returns true to accept, false to decline.
	
	Default implementation accepts all interactions.
	Override in specific states for custom behavior.
	"""
	agent.add_observation("Accepted incoming %s" % bid_observation.interaction_name)
	return true

func handle_bid(bid_observation: InteractionRequestObservation) -> Action:
	"""Handle incoming bid and return an action if the state should respond.
	
	Returns null if the state should not respond to bids.
	Returns a RESPOND_TO_INTERACTION_BID action if the state wants to respond.
	"""
	# By default, call the existing method and return a response action
	var should_accept = handle_incoming_interaction_bid(bid_observation)
	return Action.new(
		Action.Type.RESPOND_TO_INTERACTION_BID,
		{
			"bid_id": bid_observation.bid_id,
			"accept": should_accept,
			"reason": ""
		}
	)
