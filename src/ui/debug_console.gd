class_name DebugConsole
extends Control

## A minimalist debug console for developer commands
## Styled similar to The Sims cheat console

const MAX_HISTORY: int = 50
const MAX_OUTPUT_LINES: int = 100
const CONSOLE_HEIGHT_COLLAPSED: float = 40.0
const CONSOLE_HEIGHT_EXPANDED: float = 200.0
const SLIDE_DURATION: float = 0.15

# UI References
@onready var panel: Panel = $Panel
@onready var output_label: RichTextLabel = $Panel/VBoxContainer/OutputLabel
@onready var input_field: LineEdit = $Panel/VBoxContainer/InputField

# Console state
var command_history: Array[String] = []
var history_index: int = -1
var commands: Dictionary = {}
var is_expanded: bool = false

# Colors (neutral scheme)
const PANEL_COLOR = Color(0.1, 0.1, 0.1, 0.95)  # Near black with slight transparency
const TEXT_COLOR = Color(0.9, 0.9, 0.9)  # Light gray
const INPUT_COLOR = Color(1.0, 1.0, 1.0)  # White
const ERROR_COLOR = Color(1.0, 0.4, 0.4)  # Light red
const SUCCESS_COLOR = Color(0.4, 1.0, 0.4)  # Light green
const INFO_COLOR = Color(0.6, 0.8, 1.0)  # Light blue

signal console_toggled(is_open: bool)


func _ready() -> void:
	visible = false
	
	# Set up panel style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = PANEL_COLOR
	style_box.corner_radius_top_left = 0
	style_box.corner_radius_top_right = 0
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	style_box.content_margin_left = 8
	style_box.content_margin_right = 8
	style_box.content_margin_top = 8
	style_box.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Configure output
	output_label.modulate = TEXT_COLOR
	output_label.scroll_following = true
	output_label.bbcode_enabled = true
	output_label.fit_content = true
	
	# Configure input
	input_field.modulate = INPUT_COLOR
	input_field.placeholder_text = "Type 'help' for commands..."
	input_field.text_submitted.connect(_on_input_submitted)
	input_field.caret_blink = true
	
	# Set initial size
	custom_minimum_size.y = CONSOLE_HEIGHT_COLLAPSED
	size.y = CONSOLE_HEIGHT_COLLAPSED
	
	# Register built-in commands
	_register_default_commands()
	
	# Position at top center
	_update_position()
	get_viewport().size_changed.connect(_update_position)


func _input(event: InputEvent) -> void:
	# Toggle console with tilde/backtick
	if event.is_action_pressed("toggle_debug_console"):
		toggle()
		get_viewport().set_input_as_handled()
		
	# Handle history navigation when console is open
	if visible and input_field.has_focus():
		if event.is_action_pressed("ui_up"):
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_navigate_history(1)
			get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		hide_console()
	else:
		show_console()


func show_console() -> void:
	visible = true
	input_field.grab_focus()
	input_field.clear()
	history_index = command_history.size()
	
	# Animate expansion
	if not is_expanded:
		is_expanded = true
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUART)
		tween.tween_property(self, "custom_minimum_size:y", CONSOLE_HEIGHT_EXPANDED, SLIDE_DURATION)
		tween.tween_property(self, "size:y", CONSOLE_HEIGHT_EXPANDED, SLIDE_DURATION)
		
	console_toggled.emit(true)


func hide_console() -> void:
	# Animate collapse
	if is_expanded:
		is_expanded = false
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUART)
		tween.tween_property(self, "custom_minimum_size:y", CONSOLE_HEIGHT_COLLAPSED, SLIDE_DURATION)
		tween.tween_property(self, "size:y", CONSOLE_HEIGHT_COLLAPSED, SLIDE_DURATION)
		await tween.finished
		
	visible = false
	if input_field:
		input_field.release_focus()
		
	console_toggled.emit(false)


func _update_position() -> void:
	# Center at top of screen
	var viewport_size = get_viewport().size
	position.x = (viewport_size.x - size.x) / 2.0
	position.y = 0


func _navigate_history(direction: int) -> void:
	if command_history.is_empty():
		return
		
	history_index = clamp(history_index + direction, 0, command_history.size())
	
	if history_index < command_history.size():
		input_field.text = command_history[history_index]
		input_field.caret_column = input_field.text.length()
	else:
		input_field.clear()


func _on_input_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
		
	# Add to history
	command_history.append(text)
	if command_history.size() > MAX_HISTORY:
		command_history.pop_front()
	history_index = command_history.size()
	
	# Echo command
	append_output("> " + text, TEXT_COLOR)
	
	# Process command
	_process_command(text.strip_edges())
	
	# Clear input
	input_field.clear()


func _process_command(command_text: String) -> void:
	var parts = command_text.split(" ", false)
	if parts.is_empty():
		return
		
	var command = parts[0].to_lower()
	var args = parts.slice(1)
	
	if command in commands:
		var result = commands[command].callback.call(args)
		if result:
			append_output(result)
	else:
		append_output("Unknown command: '%s'. Type 'help' for available commands." % command, ERROR_COLOR)


func register_command(name: String, callback: Callable, description: String = "") -> void:
	commands[name.to_lower()] = {
		"callback": callback,
		"description": description
	}


func append_output(text: String, color: Color = TEXT_COLOR) -> void:
	var color_hex = "#" + color.to_html(false)
	output_label.append_text("[color=%s]%s[/color]\n" % [color_hex, text])
	
	# Limit output lines
	var line_count = output_label.get_line_count()
	if line_count > MAX_OUTPUT_LINES:
		# This is a bit hacky but Godot doesn't have a clean way to remove lines from RichTextLabel
		var all_text = output_label.get_parsed_text()
		var lines = all_text.split("\n")
		var keep_lines = lines.slice(lines.size() - MAX_OUTPUT_LINES)
		output_label.clear()
		output_label.append_text(keep_lines.join("\n"))


func _register_default_commands() -> void:
	# Help command
	register_command("help", _cmd_help, "Show available commands")
	register_command("clear", _cmd_clear, "Clear console output")
	register_command("backend", _cmd_backend, "Switch NPC backend (mock/mcp)")
	register_command("quit", _cmd_quit, "Hide the console")


func _cmd_help(args: Array) -> String:
	var help_text = "Available commands:\n"
	
	var sorted_commands = commands.keys()
	sorted_commands.sort()
	
	for cmd in sorted_commands:
		var info = commands[cmd]
		help_text += "  [color=%s]%s[/color]" % [INFO_COLOR.to_html(false), cmd]
		if info.description:
			help_text += " - %s" % info.description
		help_text += "\n"
		
	return help_text


func _cmd_clear(_args: Array) -> String:
	output_label.clear()
	return ""


func _cmd_backend(args: Array) -> String:
	if args.is_empty():
		var current = NpcClientFactory.get_backend_name(NpcClientFactory.current_backend)
		return "Current backend: %s" % current
		
	var backend = args[0].to_lower()
	match backend:
		"mock":
			NpcClientFactory.switch_backend(NpcClientFactory.BackendType.MOCK)
			append_output("Switched to mock backend", SUCCESS_COLOR)
			return ""
		"mcp":
			NpcClientFactory.switch_backend(NpcClientFactory.BackendType.MCP)
			append_output("Switched to MCP backend", SUCCESS_COLOR)
			return ""
		_:
			return "Invalid backend. Use 'mock' or 'mcp'"


func _cmd_quit(_args: Array) -> String:
	hide_console()
	return ""