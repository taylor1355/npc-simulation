extends BaseAgentState

class_name InteractingState

func update(_seen_items: Array, needs: Dictionary) -> Action:
	# Get current interaction from observation
	var current_interaction = agent.current_observation.current_interaction
	if not current_interaction:
		return Action.wait()
		
	if NeedManager.should_cancel_interaction(agent.id, current_interaction, needs):
		return Action.cancel_interaction()
		
	return Action.continue_action()
