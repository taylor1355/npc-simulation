@tool
extends Panel

@onready var memory_text: RichTextLabel = $MarginContainer/WorkingMemoryText

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	FieldEvents.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.FOCUSED_GAMEPIECE_CHANGED):
				_on_focused_gamepiece_changed(event as GamepieceEvents.FocusedEvent)
			elif event.is_type(Event.Type.NPC_INFO_RECEIVED):
				_on_npc_info_received(event as NpcClientEvents.InfoReceivedEvent)
	)
	
	# Handle initial focused gamepiece
	if Globals.focused_gamepiece:
		var npc_controller = Globals.focused_gamepiece.get_controller() as NpcController
		if npc_controller:
			Globals.npc_client.get_npc_info(npc_controller.npc_id)

func _on_focused_gamepiece_changed(event: GamepieceEvents.FocusedEvent) -> void:
	var gamepiece = event.gamepiece
	if not gamepiece:
		memory_text.text = "Select an NPC to view their working memory."
		return
		
	var npc_controller = gamepiece.get_controller() as NpcController
	if not npc_controller:
		memory_text.text = "Selected gamepiece is not an NPC."
		return
		
	# Request NPC info which will trigger memory update
	Globals.npc_client.get_npc_info(npc_controller.npc_id)

func _on_npc_info_received(event: NpcClientEvents.InfoReceivedEvent) -> void:
	if not Globals.focused_gamepiece:
		return
		
	var npc_controller = Globals.focused_gamepiece.get_controller() as NpcController
	if npc_controller and event.npc_id == npc_controller.npc_id:
		memory_text.text = event.working_memory
