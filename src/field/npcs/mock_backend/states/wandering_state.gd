extends BaseAgentState

class_name WanderingState

func update(seen_items: Array, needs: Dictionary) -> Action:
	if should_check_needs() and NeedUtils.needs_require_attention(needs):
		return NeedUtils.find_best_item(agent.id, seen_items, needs, agent.movement_locked)
	
	if agent.movement_locked:
		return Action.wait()
	return Action.continue_action()
