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
		print("[%s] IdleState: Found %d nearby NPCs" % [agent.id, nearby_npcs.size()])
		if not nearby_npcs.is_empty():
			print("[%s] IdleState: Nearby NPCs: %s" % [agent.id, nearby_npcs.map(func(n): return n.get("name", "unknown"))])
		if not nearby_npcs.is_empty() and randf() < 0.8:  # 80% chance to start conversation (increased for debugging)
			# Pick a random NPC to talk to
			var target = nearby_npcs.pick_random()
			agent.last_conversation_time = current_time
			print("[%s] IdleState: Starting conversation with %s" % [agent.id, target["name"]])
			return Action.interact_with(target["name"], "conversation")
	
	if should_check_needs() and NeedUtils.needs_require_attention(needs):
		return NeedUtils.find_best_item(agent.id, seen_items, needs, agent.movement_locked)
	
	return Action.wander()

func _get_nearby_npcs_from_observation() -> Array:
	if not agent.current_observation:
		print("[%s] IdleState: No current observation" % agent.id)
		return []
	
	var vision_obs = agent.current_observation.find_observation(VisionObservation)
	if not vision_obs:
		print("[%s] IdleState: No vision observation found" % agent.id)
		return []
	
	print("[%s] IdleState: Vision has %d entities" % [agent.id, vision_obs.visible_entities.size()])
	
	var npcs = []
	for entity in vision_obs.visible_entities:
		print("[%s] IdleState: Checking entity %s, interactions: %s" % [agent.id, entity.get("name", "unknown"), entity.get("interactions", {})])
		# NPCs will have conversation interaction available
		if entity.get("interactions", {}).has("conversation"):
			npcs.append(entity)
			print("[%s] IdleState: Found NPC with conversation: %s" % [agent.id, entity.get("name", "unknown")])
	
	return npcs
