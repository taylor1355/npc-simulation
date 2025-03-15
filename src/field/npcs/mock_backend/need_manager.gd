extends RefCounted

class_name NeedManager

const NEED_HYSTERESIS = 10.0  # Hysteresis for need changes
const NEED_CRITICAL_THRESHOLD = 20.0  # Point at which needs become critical
const NEED_SEARCH_THRESHOLD = 90.0  # Point at which NPCs start looking for items
const NEED_SATISFIED_THRESHOLD = 99.0  # Point at which needs are considered satisfied

static func get_interaction_for_need(agent_id: String, item: Dictionary, need_id: String) -> String:
	"""Get the appropriate interaction for a given need"""
	print("[%s] Finding interaction for need %s in item %s with interactions %s" % [
		agent_id, need_id, item.name, item.interactions
	])
	
	for interaction_name in item.interactions:
		var interaction = item.interactions[interaction_name]
		if need_id in interaction.needs_filled:
			print("[%s] Found interaction: %s" % [agent_id, interaction_name])
			return interaction_name
	
	print("[%s] No matching interaction found" % agent_id)
	return ""

static func score_item_interactions(agent_id: String, item: Dictionary, needs: Dictionary) -> Dictionary:
	"""
	Score an item's interactions based on how critical the needs they satisfy are
	Returns: Dictionary with best_interaction and score, or empty if no interactions
		which satisfy critical needs are found
	"""
	var best_interaction_name = ""
	var best_score = 0.0
	
	if not item.interactions or item.current_interaction:
		return {}
	
	for interaction_name in item.interactions:
		var interaction = item.interactions[interaction_name]
		
		# Check each need this interaction fills
		for need_id in interaction.needs_filled:
			if not needs.has(need_id):
				continue
				
			var need_value = needs[need_id]
			# Only consider critical needs
			if need_value > NEED_CRITICAL_THRESHOLD:
				continue
				
			# Calculate score based on how critical the need is
			var score = NEED_CRITICAL_THRESHOLD - need_value
			
			print("[%s] Evaluating interaction %s for need %s (value=%s, score=%s)" % [
				agent_id, interaction_name, need_id, need_value, score
			])
			
			if best_interaction_name.is_empty() or score > best_score:
				best_interaction_name = interaction_name
				best_score = score
				print("[%s] New best interaction: %s with score %s" % [
					agent_id, best_interaction_name, best_score
				])
	
	if best_interaction_name.is_empty():
		return {}
		
	return {
		"interaction_name": best_interaction_name,
		"score": best_score
	}

static func find_best_item(agent_id: String, seen_items: Array, needs: Dictionary, movement_locked: bool) -> Action:
	"""Find the item that best satisfies current needs"""
	print("[%s] Finding best item for needs: %s" % [agent_id, needs])
	
	# Track best item and its details
	var best_item = null
	var best_interaction = ""
	var best_score = 0.0
	var best_distance = 999999
	
	for item in seen_items:
		var result = score_item_interactions(agent_id, item, needs)
		if result.is_empty():
			continue
			
		var distance = item.distance_to_npc
		
		# Update best if:
		# 1. First valid item found
		# 2. Higher score (more critical need)
		# 3. Equal score but closer distance
		if best_item == null or result.score > best_score or (result.score == best_score and distance < best_distance):
			best_item = item
			best_interaction = result.interaction_name
			best_score = result.score
			best_distance = distance
			print("[%s] New best: item=%s score=%s distance=%s" % [
				agent_id, item.name, best_score, best_distance
			])
	
	if best_item:
		print("[%s] Chose item %s with score %s at distance %s" % [
			agent_id, best_item.name, best_score, best_distance
		])
		if best_distance <= 1:
			return Action.interact_with(best_item.name, best_interaction)
		else:
			if movement_locked:
				print("[%s] Movement locked, cannot move to item" % agent_id)
				return Action.continue_action()
			return Action.move_to(best_item.cell.x, best_item.cell.y)
	
	print("[%s] No suitable items found" % agent_id)
	return Action.wander()

static func should_cancel_interaction(agent_id: String, current_interaction: Dictionary, needs: Dictionary) -> bool:
	"""Check if current interaction should be canceled based on needs"""
	print("[%s] Checking cancel for %s - needs: %s" % [agent_id, current_interaction.interaction_name, needs])
	
	# Get the needs this interaction satisfies
	var filled_needs = current_interaction.needs_filled
	if filled_needs.is_empty():
		print("[%s] Interaction %s doesn't fill any needs, canceling" % [agent_id, current_interaction.interaction_name])
		return true
	
	# Get primary need (first in the list)
	var primary_need = filled_needs[0]
	
	# Cancel if current need is satisfied
	if needs[primary_need] >= NEED_SATISFIED_THRESHOLD:
		print("[%s] Canceling %s - %s satisfied (%s >= %s)" % [
			agent_id, current_interaction.name, primary_need, needs[primary_need], NEED_SATISFIED_THRESHOLD
		])
		return true
		
	# Continue if current need is near critical
	if needs[primary_need] <= NEED_CRITICAL_THRESHOLD + NEED_HYSTERESIS:
		print("[%s] Continuing %s - %s critical (%s <= %s)" % [
			agent_id, current_interaction.interaction_name, primary_need, needs[primary_need], 
			NEED_CRITICAL_THRESHOLD + NEED_HYSTERESIS
		])
		return false
	
	# Cancel if different need is critical
	for need_id in needs:
		if need_id == primary_need:
			continue
			
		if needs[need_id] <= NEED_CRITICAL_THRESHOLD:
			print("[%s] Canceling %s - %s critical (%s)" % [
				agent_id, current_interaction.interaction_name, need_id, needs[need_id]
			])
			return true
	
	print("[%s] No reason to cancel %s" % [agent_id, current_interaction.interaction_name])
	return false

static func needs_require_attention(needs: Dictionary) -> bool:
	"""Check if any needs require attention"""
	for need_id in needs:
		if needs[need_id] < NEED_SEARCH_THRESHOLD:
			return true
	return false
