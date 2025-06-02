extends GamepiecePanel

@onready var memory_text: RichTextLabel = $MarginContainer/WorkingMemoryText

func is_compatible_with(controller: GamepieceController) -> bool:
	return controller is NpcController

func _show_default_text() -> void:
	memory_text.text = "Select an NPC to view their working memory."

func _show_invalid_text() -> void:
	memory_text.text = "Selected gamepiece is not an NPC."

func _setup() -> void:
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.NPC_INFO_RECEIVED):
				_on_npc_info_received(event as NpcClientEvents.InfoReceivedEvent)
	)

func _update_display() -> void:
	if not current_controller:
		return
		
	var npc_controller = current_controller as NpcController
	if npc_controller:
		Globals.npc_client.get_npc_info(npc_controller.npc_id)

func _on_npc_info_received(event: NpcClientEvents.InfoReceivedEvent) -> void:
	if not current_controller:
		return
		
	var npc_controller = current_controller as NpcController
	if npc_controller and event.npc_id == npc_controller.npc_id:
		memory_text.text = event.working_memory
