extends BaseAgentState

class_name MovingToTargetState

func _init(agent_ref):
	super(agent_ref)
	expected_controller_state = "MOVING"

func _do_update(seen_items: Array, needs: Dictionary) -> Action:
	if agent.movement_locked:
		return Action.wait()
	
	# Look for items at our target location
	for item in seen_items:
		if item.cell != agent.target_position:
			continue
			
		# Found an item at target - try to interact if close enough
		if item.distance_to_npc <= 1 and item.interactions and not item.current_interaction:
			# Only score interactions if we have needs data
			if not needs.is_empty():
				var result = NeedUtils.score_item_interactions(agent.id, item, needs)
				if not result.is_empty():
					return Action.interact_with(item.name, result.interaction_name)
		
		# Item exists at target, keep moving toward it
		return Action.move_to(agent.target_position.x, agent.target_position.y)
	
	# No items at target location - it was consumed or is unavailable
	return Action.wander()
