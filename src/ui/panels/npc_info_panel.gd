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
		var text = "[b]Name:[/b] " + npc_controller.get_display_name() + "\n"
		text += "Loading traits..."
		traits_text.text = text
		npc_controller.npc_client.get_npc_info(npc_controller.npc_id)
	else:
		traits_text.text = "No NPC information available."

func _on_npc_info_received(event: NpcClientEvents.InfoReceivedEvent) -> void:
	if not current_controller or event.npc_id != current_controller.npc_id:
		return
		
	var text = "[b]Name:[/b] " + current_controller.get_display_name() + "\n"
	text += "[b]Traits:[/b] "
	
	var traits_str := ""
	for i in event.traits.size():
		if i > 0:
			traits_str += ", "
		traits_str += event.traits[i]
	
	text += traits_str
	traits_text.text = text
