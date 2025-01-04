class_name SittableComponent extends ItemComponent

const INTERACTION_NAME: = "sit"

var current_npc: NpcController = null
var item_controller: ItemController
var need_modifying: NeedModifyingComponent

func _ready() -> void:
	super._ready()

	item_controller = get_parent() as ItemController
	
	# Create the need modifying component for energy regeneration
	need_modifying = NeedModifyingComponent.new()
	need_modifying.need_rates = {
		"energy": 10.0  # Regenerate energy at 10 units per second
	}
	add_child(need_modifying)

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
	
	print("[SittableComponent] Starting sit interaction")
	print("[SittableComponent] NPC at ", current_npc._gamepiece.cell, ", Chair at ", chair_cell)
	
	# Lock NPC movement first to prevent any automatic movement
	print("[SittableComponent] Locking NPC movement")
	current_npc.set_movement_locked(true)
	
	# Disable chair blocking and wait a frame to ensure physics updates
	print("[SittableComponent] Disabling chair blocking")
	item_controller._gamepiece.blocks_movement = false
	await item_controller.get_tree().physics_frame
	
	# Move NPC to chair's position
	print("[SittableComponent] Moving NPC to chair position")
	current_npc._gamepiece.cell = chair_cell
	
	# Face NPC in chair's direction
	print("[SittableComponent] Setting NPC direction to ", item_controller._gamepiece.direction)
	current_npc._gamepiece.direction = item_controller._gamepiece.direction
	
	# Ensure NPC appears in front of chair
	print("[SittableComponent] Setting NPC z_index to appear in front")
	current_npc._gamepiece.z_index = item_controller._gamepiece.z_index + 1
	
	# Wait another frame before re-enabling blocking
	await item_controller.get_tree().physics_frame
	print("[SittableComponent] Re-enabling chair blocking")
	item_controller._gamepiece.blocks_movement = true
	
	print("[SittableComponent] Final positions - NPC: ", current_npc._gamepiece.cell, ", Chair: ", chair_cell)
	
	# Start energy regeneration
	need_modifying._handle_modify_start_request(request)


func _handle_sit_cancel_request(request: InteractionRequest) -> void:
	if current_npc and current_npc == request.npc_controller:
		request.accept()
		_finish_interaction()
	else:
		request.reject("Not sitting in chair")


func _finish_interaction() -> void:
	if current_npc:
		var chair_cell = item_controller._gamepiece.cell
		var chair_direction = item_controller._gamepiece.direction
		
		print("[SittableComponent] Starting exit interaction")
		print("[SittableComponent] Current positions - NPC: ", current_npc._gamepiece.cell, ", Chair: ", chair_cell)
		print("[SittableComponent] Chair direction: ", chair_direction)
		
		# Try to find an unblocked adjacent cell
		var possible_cells = [
			chair_cell + Vector2i(chair_direction), # In front
			chair_cell + Vector2i(chair_direction.rotated(-PI/2)), # Left
			chair_cell + Vector2i(chair_direction.rotated(PI/2)),  # Right
			chair_cell - Vector2i(chair_direction), # Behind
		]
		
		print("[SittableComponent] Checking possible exit cells:")
		var exit_cell = null
		for cell in possible_cells:
			print("[SittableComponent] Checking cell ", cell)
			if not current_npc.is_cell_blocked(cell):
				print("[SittableComponent] Found unblocked cell at ", cell)
				exit_cell = cell
				break
			else:
				print("[SittableComponent] Cell ", cell, " is blocked")
		
		# Temporarily disable chair blocking for exit
		print("[SittableComponent] Disabling chair blocking for exit")
		item_controller._gamepiece.blocks_movement = false
		
		# If we found an unblocked cell, move there
		if exit_cell:
			print("[SittableComponent] Moving NPC to exit cell ", exit_cell)
			current_npc._gamepiece.cell = exit_cell
		else:
			print("[SittableComponent] No unblocked exit cells found, NPC staying at ", current_npc._gamepiece.cell)
		
		# Re-enable chair blocking
		print("[SittableComponent] Re-enabling chair blocking")
		item_controller._gamepiece.blocks_movement = true
		
		# Reset NPC z_index and unlock movement
		print("[SittableComponent] Resetting NPC z_index")
		current_npc._gamepiece.z_index = 0
		print("[SittableComponent] Unlocking NPC movement")
		current_npc.set_movement_locked(false)
		
		need_modifying._finish_interaction()
		current_npc = null
		interaction_finished.emit(INTERACTION_NAME, {})
