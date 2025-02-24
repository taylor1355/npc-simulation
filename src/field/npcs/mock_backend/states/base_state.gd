class_name BaseAgentState

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
	return Action.wait()  # Base state does nothing
	
func should_check_needs() -> bool:
	return true  # Most states should check needs
