extends BaseAgentState

class_name IdleState

func update(seen_items: Array, needs: Dictionary) -> Action:
	if agent.idle_timer > 0:
		return Action.wait()
	
	# Check for conversation opportunities when idle and not recently conversed
	var current_time = Time.get_unix_time_from_system()
	var time_since_conversation = current_time - agent.last_conversation_time
	if time_since_conversation > agent.conversation_cooldown:
		var nearby_npcs = _get_nearby_npcs_from_observation()
		if not nearby_npcs.is_empty() and randf() < 0.3:  # 30% chance to start conversation
			# Pick a random NPC to talk to
			var target = nearby_npcs.pick_random()
			agent.last_conversation_time = current_time
			return Action.new(
				Action.Type.START_CONVERSATION,
				{"target_npcs": [target["name"]]}
			)
	
	if should_check_needs() and NeedUtils.needs_require_attention(needs):
		return NeedUtils.find_best_item(agent.id, seen_items, needs, agent.movement_locked)
	
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
