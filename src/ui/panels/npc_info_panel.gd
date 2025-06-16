extends GamepiecePanel

@onready var traits_text: RichTextLabel = $MarginContainer/TraitsText

func is_compatible_with(controller: GamepieceController) -> bool:
	return controller is NpcController

func _setup() -> void:
	# Listen for NPC info events
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.NPC_INFO_RECEIVED):
				_on_npc_info_received(event as NpcClientEvents.InfoReceivedEvent)
			elif event.is_type(Event.Type.NPC_STATE_CHANGED):
				_on_npc_state_changed(event as NpcEvents.StateChangedEvent)
	)

func _show_default_text() -> void:
	traits_text.text = "Select an NPC to view their traits."

func _show_invalid_text() -> void:
	traits_text.text = "Not an NPC."

func _update_display() -> void:
	if not current_controller:
		return
		
	var npc_controller := current_controller as NpcController
	if npc_controller and npc_controller.npc_id:
		_display_info()
		npc_controller.npc_client.get_npc_info(npc_controller.npc_id)
	else:
		traits_text.text = "No NPC information available."

func _on_npc_info_received(event: NpcClientEvents.InfoReceivedEvent) -> void:
	if not current_controller or event.npc_id != current_controller.npc_id:
		return
		
	_display_info(event.traits)

func _on_npc_state_changed(event: NpcEvents.StateChangedEvent) -> void:
	if not current_controller:
		return
	
	var npc_controller := current_controller as NpcController
	if not npc_controller or event.npc != npc_controller._gamepiece:
		return
	
	# Just refresh the display - controller has the latest state
	_display_info()

func _display_info(traits: Array = []) -> void:
	var npc_controller := current_controller as NpcController
	if not npc_controller:
		return
		
	var text = "[b]Name:[/b] " + npc_controller.get_display_name() + "\n"
	
	# Add state info from controller
	var state_info = npc_controller.get_state_info_text()
	if state_info:
		text += "[b]State:[/b] " + state_info + "\n"
	
	# Add traits
	if traits.size() > 0:
		text += "[b]Traits:[/b] " + ", ".join(traits)
	else:
		text += "[b]Traits:[/b] Loading..."
	
	traits_text.text = text
