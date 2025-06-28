class_name NpcNameplate
extends Node2D

@onready var name_label: Label = $NameLabel
@onready var emoji_label: Label = $EmojiLabel

var _controller: NpcController

func _ready() -> void:
	# Get the controller via the gamepiece owner
	if owner is Gamepiece:
		var gamepiece = owner as Gamepiece
		_controller = gamepiece.get_controller() as NpcController
		if not _controller:
			push_error("NpcNameplate requires an NpcController")
			return
	else:
		push_error("NpcNameplate must be part of a Gamepiece scene")
		return
	
	# Wait for controller to be ready if needed
	if not _controller.is_node_ready():
		await _controller.ready
	
	# Connect to display name updates
	_connect_to_controller()
	
	# Listen for state changes via EventBus
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.is_type(Event.Type.NPC_STATE_CHANGED):
				var state_event = event as NpcEvents.StateChangedEvent
				# Only update if this event is for our NPC
				if state_event.npc == owner:
					_update_state_emoji_from_state(state_event.new_state)
	)

func _connect_to_controller() -> void:
	# Wait a frame for display name to be set
	await get_tree().process_frame
	
	# Set initial name
	var display_name = _controller.get_display_name()
	name_label.text = display_name
	
	# Set initial emoji if state machine is ready
	if _controller.state_machine and _controller.state_machine.current_state:
		_update_state_emoji_from_state(_controller.state_machine.current_state)

func _update_state_emoji_from_state(state: BaseControllerState) -> void:
	if state:
		emoji_label.text = state.get_state_emoji()