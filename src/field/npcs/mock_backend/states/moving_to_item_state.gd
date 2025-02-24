extends BaseAgentState

class_name MovingToItemState

func update(seen_items: Array, needs: Dictionary) -> Action:
	if agent.movement_locked:
		return Action.wait()
	
	# Check if we've reached the target
	for item in seen_items:
		if item.cell != agent.target_position:
			continue
			
		if item.distance_to_npc <= 1 and item.interactions and not item.current_interaction:
			var result = NeedManager.score_item_interactions(agent.id, item, needs)
			if not result.is_empty():
				return Action.interact_with(item.name, result.interaction)
	
	# Continue moving to target
	return Action.move_to(agent.target_position.x, agent.target_position.y)
