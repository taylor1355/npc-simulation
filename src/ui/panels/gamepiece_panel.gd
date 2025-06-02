extends Panel
class_name GamepiecePanel

# Configuration
var update_interval: float = 1.0/30.0  # How often to update when visible, default 30fps

# State
var current_controller: GamepieceController = null
var time_since_update: float = 0.0

# Override in child class to specify compatibility requirements
func is_compatible_with(controller: GamepieceController) -> bool:
	return controller != null

func _ready() -> void:
	# Listen for focus changes
	EventBus.event_dispatched.connect(
		func(event: Event):
			if event.event_type == Event.Type.FOCUSED_GAMEPIECE_CHANGED:
				_on_focused_gamepiece_changed(event)
	)
	
	# Start with processing disabled
	set_process(false)
	
	# Initial setup
	_setup()

# Virtual method for additional setup
func _setup() -> void:
	pass

func _process(delta: float) -> void:
	if not current_controller:
		return
		
	time_since_update += delta
	if time_since_update >= update_interval:
		_update_display()
		time_since_update = 0.0

func _on_focused_gamepiece_changed(event: GamepieceEvents.FocusedEvent) -> void:
	if not event.gamepiece:
		current_controller = null
		_show_default_text()
		return
		
	var controller = event.gamepiece.get_controller()
	if not is_compatible_with(controller):
		current_controller = null
		_show_invalid_text()
		return
		
	current_controller = controller
	_update_display()

func activate() -> void:
	set_process(true)
	_update_display()

func deactivate() -> void:
	set_process(false)

# Virtual methods to override in child classes
func _show_default_text() -> void:
	pass

func _show_invalid_text() -> void:
	pass

func _update_display() -> void:
	pass
