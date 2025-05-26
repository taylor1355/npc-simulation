extends BaseAgentState

class_name IdleState

func update(seen_items: Array, needs: Dictionary) -> Action:
	if agent.idle_timer > 0:
		return Action.wait()
		
	if should_check_needs() and NeedUtils.needs_require_attention(needs):
		return NeedUtils.find_best_item(agent.id, seen_items, needs, agent.movement_locked)
	
	return Action.wander()
