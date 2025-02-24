extends BaseAgentState

class_name RequestingInteractionState

func update(_seen_items: Array, _needs: Dictionary) -> Action:
	# Wait for interaction to be accepted or rejected
	return Action.wait()
