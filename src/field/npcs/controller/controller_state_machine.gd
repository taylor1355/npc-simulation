class_name ControllerStateMachine extends RefCounted

enum State {
	IDLE,
	MOVING,
	REQUESTING,
	INTERACTING,
	WANDERING,
	WAITING
}

var current_state: BaseControllerState
var controller: NpcController

signal state_changed(old_state_name: String, new_state_name: String)

func _init(controller_ref: NpcController) -> void:
	controller = controller_ref
	# Start in idle state
	# current_state = ControllerIdleState.new(controller) # Old initialization
	# current_state.enter() # Old initialization
	var initial_idle_state = ControllerIdleState.new(controller)
	change_state(initial_idle_state) # Calls initial_idle_state.enter() with no action

func get_state_enum() -> State:
	if current_state is ControllerIdleState:
		return State.IDLE
	elif current_state is ControllerMovingState:
		return State.MOVING
	elif current_state is ControllerRequestingState:
		return State.REQUESTING
	elif current_state is ControllerInteractingState:
		return State.INTERACTING
	elif current_state is ControllerWanderingState:
		return State.WANDERING
	elif current_state is ControllerWaitingState:
		return State.WAITING
	else:
		return State.IDLE

func change_state(new_state: BaseControllerState, triggering_action_name: String = "", triggering_action_params: Dictionary = {}) -> void:
	var old_state_name = ""
	if current_state: # current_state might be null initially if not set in _init before first change_state
		old_state_name = current_state.state_name
		current_state.exit()
	
	current_state = new_state
	# Pass the action that triggered this state change to the new state's enter method
	current_state.enter(triggering_action_name, triggering_action_params) 
	
	if old_state_name != "" and old_state_name != new_state.state_name: # Avoid emitting signal if there was no old state or state is same
		state_changed.emit(old_state_name, new_state.state_name)
	elif old_state_name == "" and new_state.state_name != "None": # Initial state
		state_changed.emit("None", new_state.state_name)


func handle_action(action_name: String, parameters: Dictionary) -> bool:
	return current_state.handle_action(action_name, parameters)

func on_gamepiece_arrived() -> void:
	current_state.on_gamepiece_arrived()

func get_state_info() -> Dictionary:
	return {
		"state_name": current_state.state_name,
		"state_enum": State.keys()[get_state_enum()],
		"context_data": current_state.get_context_data()
	}

func is_movement_allowed() -> bool:
	return current_state.is_movement_allowed()

func is_in_state(state: State) -> bool:
	return get_state_enum() == state
