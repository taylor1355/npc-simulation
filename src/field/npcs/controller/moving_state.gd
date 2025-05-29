extends BaseControllerState

class_name ControllerMovingState

var destination: Vector2i
var allow_adjacent: bool = false

func _init(controller_ref: NpcController) -> void:
	super(controller_ref)

func enter(action_name: String = "", parameters: Dictionary = {}) -> void:
	super.enter(action_name, parameters) # Call base if it has logic
	if action_name == "move_to" and parameters.has("x") and parameters.has("y"):
		self.destination = Vector2i(parameters.x, parameters.y)
		# It's important that NpcController's set_new_destination is called
		# to trigger the actual gamepiece movement.
		controller.set_new_destination(self.destination)
	elif not destination: # If destination wasn't set by params and isn't already set
		push_error("MovingState entered without a destination and no 'move_to' action.")
		# Fallback or error state? For now, assume destination must be set.
		# Could transition to Idle if destination is invalid.
		controller.state_machine.change_state(ControllerIdleState.new(controller))
	# If destination was already set (e.g. by a direct property set before transition, though this is not the new pattern)
	# and no "move_to" action, this state will use the pre-set destination.
	# The new pattern is that 'destination' is set here in 'enter' via parameters.

func handle_action(action_name: String, parameters: Dictionary) -> bool:
	match action_name:
		"continue":
			# Continue moving is valid
			return true
		"wait":
			# Interrupt movement to wait
			controller.state_machine.change_state(ControllerWaitingState.new(controller), action_name, parameters)
			return true
		"interact_with":
			# Interrupt movement to interact
			controller.state_machine.change_state(ControllerRequestingState.new(controller), action_name, parameters)
			return true
		_:
			return super.handle_action(action_name, parameters)

func on_gamepiece_arrived() -> void:
	controller.state_machine.change_state(ControllerIdleState.new(controller))

func get_context_data() -> Dictionary:
	return {
		"destination": {"x": destination.x, "y": destination.y},
		"allow_adjacent": allow_adjacent
	}
