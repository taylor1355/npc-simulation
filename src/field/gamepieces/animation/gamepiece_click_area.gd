extends Area2D

var moused_over: bool = false
var ui_element_id: String = ""

@onready var _sprite: Sprite2D = $"../Sprite" as Sprite2D

signal clicked(ui_element_id: String)


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Register this UI element when the gamepiece is available
	await get_tree().process_frame
	var gamepiece = _get_gamepiece()
	if gamepiece:
		ui_element_id = UIRegistry.register_ui_element(Globals.UIElementType.CLICK_AREA, gamepiece)


func _get_gamepiece() -> Gamepiece:
	# Get gamepiece from metadata set by Gamepiece._register_collision_areas()
	if has_meta(Globals.GAMEPIECE_META_KEY):
		return get_meta(Globals.GAMEPIECE_META_KEY) as Gamepiece
	return null


func _on_mouse_entered() -> void:
	moused_over = true
	
	# Emit hover started event - UIRegistry will handle tinting
	var gamepiece = _get_gamepiece()
	if gamepiece:
		var event = GamepieceEvents.create_hover_started(gamepiece, ui_element_id)
		EventBus.dispatch(event)


func _on_mouse_exited() -> void:
	moused_over = false
	
	# Emit hover ended event - UIRegistry will handle tinting
	var gamepiece = _get_gamepiece()
	if gamepiece:
		var event = GamepieceEvents.create_hover_ended(gamepiece, ui_element_id)
		EventBus.dispatch(event)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_action_pressed("select") and moused_over:
		clicked.emit(ui_element_id)

func _exit_tree() -> void:
	if ui_element_id:
		UIRegistry.unregister_ui_element(ui_element_id)
