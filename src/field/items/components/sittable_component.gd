class_name SittableComponent extends ItemComponent

const INTERACTION_NAME: = "sit"

func _get_timestamp_str() -> String:
	return "%.2f" % Time.get_unix_time_from_system()

var current_npc: NpcController = null
var item_controller: ItemController
var need_modifier: NeedModifyingComponent

# Prevent multiple exits from running at once
var _is_exiting := false


func _ready() -> void:
	super._ready()

	item_controller = get_parent() as ItemController
	
	# Create the need modifying component for energy regeneration
	need_modifier = NeedModifyingComponent.new()
	need_modifier.need_rates = {
		"energy": 10.0  # Regenerate energy at 10 units per second
	}
	add_child(need_modifier)

	var interaction = Interaction.new(INTERACTION_NAME, "Sit in this chair.")
	interactions[interaction.name] = interaction
	interaction.start_request.connect(_handle_sit_start_request)
	interaction.cancel_request.connect(_handle_sit_cancel_request)


func _handle_sit_start_request(request: InteractionRequest) -> void:
	# Verify chair is unoccupied
	if current_npc:
		request.reject("Chair is already occupied")
		return
		
	# Verify NPC is adjacent to chair
	var npc_cell = request.npc_controller._gamepiece.cell
	var chair_cell = item_controller._gamepiece.cell
	if npc_cell.distance_to(chair_cell) > 1:
		request.reject("Too far from chair")
		return

	request.accept()
	current_npc = request.npc_controller
	
	# Lock NPC movement and prepare chair
	current_npc.set_movement_locked(true)
	item_controller._gamepiece.blocks_movement = false
	await item_controller.get_tree().physics_frame
	
	# Move NPC to chair and set z-index since they're in the same cell
	current_npc._gamepiece.cell = chair_cell
	current_npc._gamepiece.direction = item_controller._gamepiece.direction
	current_npc._gamepiece.z_index = item_controller._gamepiece.z_index + 1
	
	# Re-enable chair blocking
	await item_controller.get_tree().physics_frame
	item_controller._gamepiece.blocks_movement = true
	
	# Start energy regeneration
	need_modifier._handle_modify_start_request(request)


func _handle_sit_cancel_request(request: InteractionRequest) -> void:
	if current_npc and current_npc == request.npc_controller:
		request.accept()
		_finish_interaction()
	else:
		request.reject("Not sitting in chair")


func _finish_interaction() -> void:
	if not current_npc or _is_exiting:
		return
		
	_is_exiting = true
	
	var chair_cell = item_controller._gamepiece.cell
	var chair_direction = item_controller._gamepiece.direction
	
	# Keep chair non-blocking during exit
	item_controller._gamepiece.blocks_movement = false
	
	# Find an unblocked adjacent cell
	var possible_cells = [
		chair_cell + Vector2i(chair_direction), # In front
		chair_cell + Vector2i(chair_direction.rotated(-PI/2)), # Left
		chair_cell + Vector2i(chair_direction.rotated(PI/2)),  # Right
		chair_cell - Vector2i(chair_direction), # Behind
	]
	
	# Try to move NPC to an unblocked cell
	for cell in possible_cells:
		if not current_npc.is_cell_blocked(cell):
			current_npc._gamepiece.cell = cell
			# Clear z_index since we're no longer sharing a cell with the chair
			current_npc._gamepiece.z_index = 0
			break
	
	# Re-enable chair blocking after NPC has moved
	item_controller._gamepiece.blocks_movement = true
	
	# Clean up
	need_modifier._finish_interaction()
	
	# Store reference before nulling
	var npc = current_npc
	
	# Clear references
	current_npc = null
	_is_exiting = false
	
	# Defer movement unlock and interaction finish to let NPC settle
	call_deferred("_complete_exit", npc)


func _complete_exit(npc: NpcController) -> void:
	if is_instance_valid(npc):
		npc.set_movement_locked(false)

	interaction_finished.emit(INTERACTION_NAME, {})
