extends Area2D

var moused_over: bool = false

@onready var _sprite: Sprite2D = $"../Sprite" as Sprite2D

signal clicked()


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	moused_over = true

	# Enable color tint
	_sprite.modulate = Color(1, 1, 1, 0.5)


func _on_mouse_exited() -> void:
	moused_over = false

	# Disable color tint
	_sprite.modulate = Color(1, 1, 1, 1)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_action_pressed("select") and moused_over:
		clicked.emit()
