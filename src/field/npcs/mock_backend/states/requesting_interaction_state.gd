extends BaseAgentState

class_name RequestingInteractionState

func update(_seen_items: Array, _needs: Dictionary) -> Action:
	# Wait for interaction to be accepted or rejected
	return Action.wait()

func handle_incoming_interaction_bid(bid_observation: InteractionRequestObservation) -> bool:
	"""Decline incoming bids when already requesting something"""
	agent.add_observation("Declined incoming %s - already requesting" % bid_observation.interaction_name)
	return false
