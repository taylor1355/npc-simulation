## Mock implementation of the NPC agent backend service. This simulates the server-side
## logic that would normally run remotely. Uses "agent" terminology to match the real backend.
class_name MockNpcBackend
extends Node

# Constants
const MOVEMENT_COOLDOWN = 0.75  # How long to idle after movement
const NEED_HYSTERESIS = 10.0  # Hysteresis for need changes
const NEED_CRITICAL_THRESHOLD = 20.0  # Point at which needs become critical
const NEED_SEARCH_THRESHOLD = 90.0  # Point at which NPCs start looking for items
const NEED_SATISFIED_THRESHOLD = 99.0  # Point at which needs are considered satisfied
const MAX_OBSERVATIONS = 5  # Number of observations to keep in memory

# Currently supported needs and their interactions
const SUPPORTED_NEEDS = {
	"hunger": ["consume"],
	"energy": ["sit"]
}

class Action:
	var type: NpcResponse.Action
	var parameters: Dictionary
	
	func _init(action_type: NpcResponse.Action, action_parameters: Dictionary = {}):
		type = action_type
		parameters = action_parameters
	
	static func create(action_type: NpcResponse.Action, parameters: Dictionary = {}) -> Action:
		"""Create an action with the given type and parameters"""
		return Action.new(action_type, parameters)
	
	func format_action() -> String:
		"""Get a human-readable representation of the action"""
		match type:
			NpcResponse.Action.MOVE_TO:
				return "move_to(%s, %s)" % [parameters.x, parameters.y]
			NpcResponse.Action.INTERACT_WITH:
				return "interact_with(%s, %s)" % [parameters.item_name, parameters.interaction_type]
			NpcResponse.Action.WANDER:
				return "wander"
			NpcResponse.Action.WAIT:
				return "wait"
			NpcResponse.Action.CONTINUE:
				return "continue"
			NpcResponse.Action.CANCEL_INTERACTION:
				return "cancel_interaction"
			_:
				return "unknown"

class NeedManager:
	static func get_interaction_for_need(agent_id: String, item: Dictionary, need_id: String) -> String:
		"""Get the appropriate interaction type for a given need"""
		print("[%s] Finding interaction for need %s in item %s with interactions %s" % [
			agent_id, need_id, item.name, item.interactions
		])
		
		if not SUPPORTED_NEEDS.has(need_id):
			return ""
			
		for interaction in SUPPORTED_NEEDS[need_id]:
			if item.interactions.has(interaction):
				print("[%s] Found interaction: %s" % [agent_id, interaction])
				return interaction
		
		print("[%s] No matching interaction found" % agent_id)
		return ""
	
	static func get_need_for_interaction(interaction: String) -> String:
		"""Get the need that an interaction satisfies"""
		for need_id in SUPPORTED_NEEDS:
			if interaction in SUPPORTED_NEEDS[need_id]:
				return need_id
		return ""
	
	static func score_item_interactions(agent_id: String, item: Dictionary, needs: Dictionary) -> Dictionary:
		"""
		Score an item's interactions based on how critical the needs they satisfy are
		Returns: Dictionary with best_interaction and score, or empty if no interactions
			which satisfy critical needs are found
		"""
		var best_interaction = ""
		var best_score = 0.0
		
		if not item.interactions or item.current_interaction:
			return {}
		
		for need_id in SUPPORTED_NEEDS:
			var need_value = needs[need_id]
			# Only consider critical needs
			if need_value > NEED_CRITICAL_THRESHOLD:
				continue
				
			var interaction = get_interaction_for_need(agent_id, item, need_id)
			if interaction.is_empty():
				continue
				
			# Score is inverse of need value (lower need = higher score)
			var score = NEED_CRITICAL_THRESHOLD - need_value
			
			print("[%s] Evaluating interaction %s for need %s (value=%s, score=%s)" % [
				agent_id, interaction, need_id, need_value, score
			])
			
			if best_interaction.is_empty() or score > best_score:
				best_interaction = interaction
				best_score = score
				print("[%s] New best interaction: %s with score %s" % [
					agent_id, best_interaction, best_score
				])
		
		if best_interaction.is_empty():
			return {}
			
		return {
			"interaction": best_interaction,
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
				best_interaction = result.interaction
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
				return Action.create(NpcResponse.Action.INTERACT_WITH, {
					"item_name": best_item.name,
					"interaction_type": best_interaction
				})
			else:
				if movement_locked:
					print("[%s] Movement locked, cannot move to item" % agent_id)
					return Action.create(NpcResponse.Action.CONTINUE)
				return Action.create(NpcResponse.Action.MOVE_TO, {
					"x": best_item.cell.x,
					"y": best_item.cell.y
				})
		
		print("[%s] No suitable items found" % agent_id)
		return Action.create(NpcResponse.Action.WANDER)
	
	static func should_cancel_interaction(agent_id: String, current_interaction: String, needs: Dictionary) -> bool:
		"""Check if current interaction should be canceled based on needs"""
		print("[%s] Checking cancel for %s - needs: %s" % [agent_id, current_interaction, needs])
		
		# Get the need this interaction satisfies
		var current_need = get_need_for_interaction(current_interaction)
		if current_need.is_empty():
			print("[%s] Unknown interaction %s, canceling" % [agent_id, current_interaction])
			return true
		
		# Cancel if current need is satisfied
		if needs[current_need] >= NEED_SATISFIED_THRESHOLD:
			print("[%s] Canceling %s - %s satisfied (%s >= %s)" % [
				agent_id, current_interaction, current_need, needs[current_need], NEED_SATISFIED_THRESHOLD
			])
			return true
			
		# Continue if current need is near critical
		if needs[current_need] <= NEED_CRITICAL_THRESHOLD + NEED_HYSTERESIS:
			print("[%s] Continuing %s - %s critical (%s <= %s)" % [
				agent_id, current_interaction, current_need, needs[current_need], 
				NEED_CRITICAL_THRESHOLD + NEED_HYSTERESIS
			])
			return false
		
		# Cancel if different need is critical
		for need_id in SUPPORTED_NEEDS:
			if need_id == current_need:
				continue
				
			if needs[need_id] <= NEED_CRITICAL_THRESHOLD:
				print("[%s] Canceling %s - %s critical (%s)" % [
					agent_id, current_interaction, need_id, needs[need_id]
				])
				return true
		
		print("[%s] No reason to cancel %s" % [agent_id, current_interaction])
		return false
	
	static func check_needs(needs: Dictionary) -> bool:
		"""Check if any needs require attention"""
		for need_id in SUPPORTED_NEEDS:
			if needs[need_id] < NEED_SEARCH_THRESHOLD:
				return true
		return false

class BaseAgentState:
	var agent  # Reference to the agent this state belongs to
	var state_name: String  # Name of the state for logging
	
	func _init(agent_ref):
		agent = agent_ref
		state_name = get_script().resource_path.get_file().trim_suffix("State.gd")
	
	func enter() -> void:
		pass
		
	func exit() -> void:
		pass
		
	func update(_seen_items: Array, _needs: Dictionary) -> Action:
		return Action.create(NpcResponse.Action.WAIT)  # Base state does nothing
		
	func should_check_needs() -> bool:
		return true  # Most states should check needs

class IdleState extends BaseAgentState:
	func update(seen_items: Array, needs: Dictionary) -> Action:
		if agent.idle_timer > 0:
			return Action.create(NpcResponse.Action.WAIT)
			
		if should_check_needs() and NeedManager.check_needs(needs):
			return NeedManager.find_best_item(agent.id, seen_items, needs, agent.movement_locked)
		
		return Action.create(NpcResponse.Action.WANDER)

class WanderingState extends BaseAgentState:
	func update(seen_items: Array, needs: Dictionary) -> Action:
		if should_check_needs() and NeedManager.check_needs(needs):
			return NeedManager.find_best_item(agent.id, seen_items, needs, agent.movement_locked)
		
		if agent.movement_locked:
			return Action.create(NpcResponse.Action.WAIT)
		return Action.create(NpcResponse.Action.CONTINUE)

class MovingToItemState extends BaseAgentState:
	func update(seen_items: Array, needs: Dictionary) -> Action:
		if agent.movement_locked:
			return Action.create(NpcResponse.Action.WAIT)
		
		# Check if we've reached the target
		for item in seen_items:
			if item.cell != agent.target_position:
				continue
				
			if item.distance_to_npc <= 1 and item.interactions and not item.current_interaction:
				var result = NeedManager.score_item_interactions(agent.id, item, needs)
				if not result.is_empty():
					return Action.create(NpcResponse.Action.INTERACT_WITH, {
						"item_name": item.name,
						"interaction_type": result.interaction
					})
		
		# Continue moving to target
		return Action.create(NpcResponse.Action.MOVE_TO, {
			"x": agent.target_position.x,
			"y": agent.target_position.y
		})

class RequestingInteractionState extends BaseAgentState:
	func update(seen_items: Array, needs: Dictionary) -> Action:
		# Wait for interaction to be accepted or rejected
		return Action.create(NpcResponse.Action.WAIT)

class InteractingState extends BaseAgentState:
	func update(seen_items: Array, needs: Dictionary) -> Action:
		# Get current interaction from observation
		var current_interaction = agent.current_observation.current_interaction
		if not current_interaction:
			return Action.create(NpcResponse.Action.WAIT)
			
		if NeedManager.should_cancel_interaction(agent.id, current_interaction.interaction_type, needs):
			return Action.create(NpcResponse.Action.CANCEL_INTERACTION)
			
		return Action.create(NpcResponse.Action.CONTINUE)

class Agent:
	var id: String
	var traits: Array
	var working_memory: Array[String]
	var long_term_memories: Array[String]
	
	var current_state: BaseAgentState
	var idle_timer: float = 0.0
	var target_position: Vector2i
	var last_update_time: float
	var last_processed_event_timestamp: float = 0.0
	var movement_locked: bool = false
	var current_observation = null  # Latest observation payload
	
	func change_state(new_state_type) -> void:
		# Get state names for logging
		var old_name = "None"
		if current_state:
			old_name = current_state.state_name
			current_state.exit()
		
		# Change state
		current_state = new_state_type.new(self)
		current_state.enter()
		
		# Log transition
		print("[%s] State transition: %s -> %s" % [id, old_name, current_state.state_name])
		add_observation("State changed to %s" % current_state.state_name)
	
	func _init(agent_id: String, config: Dictionary):
		id = agent_id
		traits = config.get("traits", [])
		working_memory = []
		if config.get("initial_working_memory"):
			working_memory.append(config.get("initial_working_memory"))
		long_term_memories = config.get("initial_long_term_memories", [])
		last_update_time = Time.get_unix_time_from_system()
		
		# Initialize with idle state
		change_state(IdleState)
	
	func add_observation(observation: String) -> void:
		working_memory.append("Observed: " + observation)
		if working_memory.size() > MAX_OBSERVATIONS:
			working_memory = working_memory.slice(-MAX_OBSERVATIONS)
	
	func update_timer(delta: float) -> void:
		if idle_timer > 0:
			idle_timer = max(0, idle_timer - delta)
	
	func update_state_from_action(action: Action) -> void:
		"""Update agent state based on chosen action"""
		print("[%s] Updating state from action: %s" % [id, action.format_action()])
		match action.type:
			NpcResponse.Action.MOVE_TO:
				target_position = Vector2i(
					action.parameters["x"],
					action.parameters["y"]
				)
				change_state(MovingToItemState)
			NpcResponse.Action.INTERACT_WITH:
				change_state(RequestingInteractionState)
			NpcResponse.Action.WANDER:
				if not movement_locked:
					change_state(WanderingState)
			NpcResponse.Action.CONTINUE:
				pass # Keep current state
			NpcResponse.Action.WAIT:
				change_state(IdleState)
			NpcResponse.Action.CANCEL_INTERACTION:
				change_state(IdleState)
			_:
				push_error("[%s] Unknown action: %s" % [id, action.format_action()])
	
	func choose_action(seen_items: Array, needs: Dictionary) -> Action:
		"""Choose next action based on state, needs, and environment"""
		print("\n[%s] Choosing action - needs: %s" % [id, needs])
		
		# Update timers
		var current_time = Time.get_unix_time_from_system()
		var delta = current_time - last_update_time
		last_update_time = current_time
		update_timer(delta)
		
		# If no current state, initialize to idle
		if not current_state:
			change_state(IdleState)
		
		# Get action from current state
		var action = current_state.update(seen_items, needs)
		print("[%s] Chose action: %s" % [id, action.format_action()])
		return action

# Backend state
var agents: Dictionary = {}  # Dictionary of agent_id -> Agent

func create_agent(agent_id: String, config: Dictionary) -> Dictionary:
	"""Create a new agent
	
	Args:
		agent_id: Unique identifier for the agent
		config: Configuration object containing:
			- traits: list[str], Basic personality traits
			- initial_working_memory: str, Initial working memory state
			- initial_long_term_memories: list[str], Initial long-term memories
	"""
	agents[agent_id] = Agent.new(agent_id, config)
	
	return {
		"status": "created",
		"agent_id": agent_id
	}

func process_observation(request: NpcRequest) -> NpcResponse:
	"""Process NPC events and return chosen action"""
	if not agents.has(request.npc_id):
		return NpcResponse.create_error("Agent %s not found" % request.npc_id)
	
	var agent = agents[request.npc_id]
	var needs = {}
	var seen_items = []
	
	# Process events in order
	for event in request.events:
		if event.timestamp < agent.last_processed_event_timestamp:
			continue
			
		match event.type:
			NpcEvent.Type.OBSERVATION:
				needs = event.payload.needs
				seen_items = event.payload.seen_items
				agent.movement_locked = event.payload.movement_locked
				agent.current_observation = event.payload
				
				# Update state based on current interaction
				if event.payload.current_interaction:
					if not (agent.current_state is InteractingState):
						agent.change_state(InteractingState)
				elif agent.current_state is InteractingState:
					agent.change_state(IdleState)
			NpcEvent.Type.ERROR:
				agent.add_observation("Error: " + event.payload.message)
			NpcEvent.Type.INTERACTION_REQUEST_PENDING:
				agent.add_observation("Requesting interaction: %s" % event.payload.interaction_type)
			NpcEvent.Type.INTERACTION_REQUEST_REJECTED:
				agent.add_observation("Interaction request rejected: %s (%s)" % [
					event.payload.interaction_type,
					event.payload.reason
				])
				# Go back to idle if we were requesting an interaction
				if agent.current_state is RequestingInteractionState:
					agent.change_state(IdleState)
			NpcEvent.Type.INTERACTION_STARTED:
				agent.add_observation("Interaction started: %s" % event.payload.interaction_type)
			NpcEvent.Type.INTERACTION_CANCELED, NpcEvent.Type.INTERACTION_FINISHED:
				agent.idle_timer = MOVEMENT_COOLDOWN
				
				# Log appropriate message
				var action = "canceled" if event.type == NpcEvent.Type.INTERACTION_CANCELED else "finished"
				agent.add_observation("Interaction %s: %s" % [action, event.payload.interaction_type])
		
		agent.last_processed_event_timestamp = event.timestamp
	
	var action = agent.choose_action(seen_items, needs)
	agent.update_state_from_action(action)
	
	return NpcResponse.create_success(action.type, action.parameters)

func cleanup_agent(agent_id: String) -> Dictionary:
	"""Gracefully cleanup and remove an agent from the system
	
	Args:
		agent_id: Agent to remove
	"""
	if agents.has(agent_id):
		agents.erase(agent_id)
		
	return {
		"status": "removed",
		"agent_id": agent_id
	}

func get_agent_info(agent_id: String) -> Dictionary:
	"""Get basic information about an agent in the system"""
	if not agents.has(agent_id):
		return {
			"status": "error",
			"message": "Agent %s not found" % agent_id
		}
		
	var agent = agents[agent_id]
	return {
		"status": "active",
		"traits": agent.traits,
		"working_memory": "\n".join(agent.working_memory)
	}
