extends RefCounted

class_name Agent

var id: String
var traits: Array
var working_memory: Array[String]
var long_term_memories: Array[String]

const MAX_OBSERVATIONS = 5  # Number of observations to keep in memory

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

func _init(agent_id: String, config: Dictionary[String, Variant]) -> void:
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
		Action.Type.MOVE_TO:
			target_position = Vector2i(
				action.parameters["x"],
				action.parameters["y"]
			)
			change_state(MovingToItemState)
		Action.Type.INTERACT_WITH:
			change_state(RequestingInteractionState)
		Action.Type.WANDER:
			if not movement_locked:
				change_state(WanderingState)
		Action.Type.CONTINUE:
			pass # Keep current state
		Action.Type.WAIT:
			change_state(IdleState)
		Action.Type.CANCEL_INTERACTION:
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
