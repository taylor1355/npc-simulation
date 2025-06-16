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
	
	# Connect to display name updates and state changes
	_connect_to_controller()

func _connect_to_controller() -> void:
	# Wait a frame for display name to be set
	await get_tree().process_frame
	
	# Set initial name
	name_label.text = _controller.get_display_name()
	
	# Connect to state machine for emoji updates
	if _controller.state_machine:
		_controller.state_machine.state_changed.connect(_on_state_changed)
		# Set initial emoji
		_update_state_emoji()

func _on_state_changed(_old_state: String, _new_state: String) -> void:
	_update_state_emoji()

func _update_state_emoji() -> void:
	if _controller.state_machine and _controller.state_machine.current_state:
		emoji_label.text = _controller.state_machine.current_state.get_state_emoji()