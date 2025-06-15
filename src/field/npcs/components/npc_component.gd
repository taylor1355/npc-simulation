class_name NpcComponent extends EntityComponent

# NPC-specific helper to get the NpcController
func get_npc_controller() -> NpcController:
	return controller as NpcController

# Helper to access needs manager
func get_needs_manager() -> NeedsManager:
	var npc = get_npc_controller()
	return npc.needs_manager if npc else null

# Helper to access NPC state machine
func get_state_machine() -> ControllerStateMachine:
	var npc = get_npc_controller()
	return npc.state_machine if npc else null

# Helper to check if NPC is currently interacting
func is_interacting() -> bool:
	var npc = get_npc_controller()
	return npc.current_interaction != null if npc else false

# Helper to get current interaction
func get_current_interaction() -> Interaction:
	var npc = get_npc_controller()
	return npc.current_interaction if npc else null