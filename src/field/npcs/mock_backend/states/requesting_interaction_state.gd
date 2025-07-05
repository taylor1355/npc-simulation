extends BaseAgentState

class_name RequestingInteractionState

func _init(agent_ref):
	super(agent_ref)
	expected_controller_state = "REQUESTING"

func _do_update(_seen_items: Array, _needs: Dictionary) -> Action:
	# Continue in requesting state until interaction is accepted or rejected
	return Action.continue_action()

func handle_incoming_interaction_bid(bid_observation: InteractionRequestObservation) -> bool:
	"""Decline incoming bids when already requesting something"""
	agent.add_observation("Declined incoming %s - already requesting" % bid_observation.interaction_name)
	return false

func handle_bid(bid_observation: InteractionRequestObservation) -> Action:
	"""Don't respond to bids while already requesting"""
	# Just log the rejection but don't return an action
	handle_incoming_interaction_bid(bid_observation)
	return null
