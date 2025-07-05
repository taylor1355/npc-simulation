extends RefCounted

class_name NeedUtils

class ItemMatch:
	var item: Dictionary
	var interaction_name: String
	var score: float
	var distance: float
	
	func _init(item_data: Dictionary, interaction: String, item_score: float, item_distance: float):
		item = item_data
		interaction_name = interaction
		score = item_score
		distance = item_distance

const NEED_HYSTERESIS = 10.0  # Hysteresis for need changes
const NEED_CRITICAL_THRESHOLD = 20.0  # Point at which needs become critical
const NEED_SEARCH_THRESHOLD = 50.0  # Point at which NPCs start looking for items
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
	Score an item's interactions based on how much the needs they satisfy require attention
	Returns: Dictionary with best_interaction and score, or empty if no interactions
		which satisfy needs requiring attention are found
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
			# Only consider needs that require attention (below search threshold)
			if need_value > NEED_SEARCH_THRESHOLD:
				continue
				
			# Calculate score based on how much attention the need requires
			# Higher score = more urgent (lower need value)
			var score = NEED_SEARCH_THRESHOLD - need_value
			
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

static func find_best_item(agent_id: String, seen_items: Array, needs: Dictionary) -> ItemMatch:
	"""Find the item that best satisfies current needs
	Returns: ItemMatch instance or null if nothing suitable found"""
	print("[%s] Finding best item for needs: %s" % [agent_id, needs])
	
	# Track best item and its details
	var best_match: ItemMatch = null
	
	for item in seen_items:
		var result = score_item_interactions(agent_id, item, needs)
		if result.is_empty():
			continue
			
		var distance = item.distance_to_npc
		
		# Update best if:
		# 1. First valid item found
		# 2. Higher score (more critical need)
		# 3. Equal score but closer distance
		if best_match == null or result.score > best_match.score or (result.score == best_match.score and distance < best_match.distance):
			best_match = ItemMatch.new(item, result.interaction_name, result.score, distance)
			print("[%s] New best: item=%s score=%s distance=%s" % [
				agent_id, item.name, best_match.score, best_match.distance
			])
	
	if best_match:
		print("[%s] Chose item %s with score %s at distance %s" % [
			agent_id, best_match.item.name, best_match.score, best_match.distance
		])
	else:
		print("[%s] No suitable items found" % agent_id)
	
	return best_match

static func should_cancel_interaction(agent_id: String, current_interaction: Dictionary, needs: Dictionary) -> bool:
	"""Check if current interaction should be canceled based on needs"""
	print("[%s] Checking cancel for %s - needs: %s" % [agent_id, current_interaction.name, needs])
	
	# Get the needs this interaction satisfies
	var filled_needs = current_interaction.needs_filled
	if filled_needs.is_empty():
		print("[%s] Interaction %s doesn't fill any needs, canceling" % [agent_id, current_interaction.name])
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
			agent_id, current_interaction.name, primary_need, needs[primary_need], 
			NEED_CRITICAL_THRESHOLD + NEED_HYSTERESIS
		])
		return false
	
	# Cancel if different need is critical
	for need_id in needs:
		if need_id == primary_need:
			continue
			
		if needs[need_id] <= NEED_CRITICAL_THRESHOLD:
			print("[%s] Canceling %s - %s critical (%s)" % [
				agent_id, current_interaction.name, need_id, needs[need_id]
			])
			return true
	
	print("[%s] No reason to cancel %s" % [agent_id, current_interaction.name])
	return false

static func needs_require_attention(needs: Dictionary) -> bool:
	"""Check if any needs require attention"""
	for need_id in needs:
		if needs[need_id] < NEED_SEARCH_THRESHOLD:
			return true
	return false
