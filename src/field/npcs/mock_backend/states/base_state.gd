class_name BaseAgentState

var agent  # Reference to the agent this state belongs to
var state_name: String  # Name of the state for logging

func _init(agent_ref):
	agent = agent_ref
	state_name = get_script().resource_path.get_file().trim_suffix("State.gd")

func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func update(_seen_items: Array, _needs: Dictionary) -> Action:
	return Action.wait()  # Base state does nothing
	
func should_check_needs() -> bool:
	return true  # Most states should check needs

func handle_incoming_interaction_bid(bid_observation: InteractionRequestObservation) -> bool:
	"""Handle incoming interaction bids. Returns true to accept, false to decline.
	
	Default implementation accepts all interactions.
	Override in specific states for custom behavior.
	"""
	agent.add_observation("Accepted incoming %s" % bid_observation.interaction_name)
	return true
