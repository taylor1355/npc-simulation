extends BaseAgentState

class_name IdleState

func _init(agent_ref):
	super(agent_ref)
	expected_controller_state = "IDLE"

func _do_update(seen_items: Array, needs: Dictionary) -> Action:
	if agent.idle_timer > 0:
		return Action.wait()
	
	# Check for conversation opportunities when idle
	var nearby_npcs = _get_nearby_npcs_from_observation()
	var conversation_decision = ConversationUtils.should_start_conversation(
		agent.id, 
		nearby_npcs, 
		agent.last_conversation_time
	)
	
	if conversation_decision.should_start:
		agent.last_conversation_time = Time.get_unix_time_from_system()
		return Action.interact_with(conversation_decision.target["name"], "conversation")
	
	if should_check_needs() and NeedUtils.needs_require_attention(needs):
		var best_item = NeedUtils.find_best_item(agent.id, seen_items, needs)
		if best_item:
			if best_item.distance <= 1:
				return Action.interact_with(best_item.item.name, best_item.interaction_name)
			else:
				if agent.movement_locked:
					return Action.wait()
				return Action.move_to(best_item.item.cell.x, best_item.item.cell.y)
	
	return Action.wander()

func _get_nearby_npcs_from_observation() -> Array:
	if not agent.current_observation:
		return []
	
	var vision_obs = agent.current_observation.find_observation(VisionObservation)
	if not vision_obs:
		return []
	
	var npcs = []
	for entity in vision_obs.visible_entities:
		# NPCs will have conversation interaction available
		if entity.get("interactions", {}).has("conversation"):
			npcs.append(entity)
	
	return npcs
