extends BaseAgentState

class_name WanderingState

func _init(agent_ref):
	super(agent_ref)
	expected_controller_state = "WANDERING"

func _do_update(seen_items: Array, needs: Dictionary) -> Action:
	if should_check_needs() and NeedUtils.needs_require_attention(needs):
		var best_item = NeedUtils.find_best_item(agent.id, seen_items, needs)
		if best_item:
			if best_item.distance <= 1:
				return Action.interact_with(best_item.item.name, best_item.interaction_name)
			else:
				if agent.movement_locked:
					return Action.continue_action()
				return Action.move_to(best_item.item.cell.x, best_item.item.cell.y)
	
	if agent.movement_locked:
		return Action.wait()
	return Action.continue_action()
