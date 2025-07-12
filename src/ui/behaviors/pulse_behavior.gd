class_name PulseBehavior extends BaseUIBehavior

## Behavior that creates a pulsing effect on sprites.
## Typically used to draw attention to items in certain states.

var pulse_color: Color = Color(1.0, 0.8, 0.8, 1.0)
var pulse_rate: float = 2.0  # Pulses per second

# State tracking
static var _active_pulses: Dictionary = {}  # Gamepiece -> Tween
static var _original_colors: Dictionary = {}  # Gamepiece -> Dictionary of Sprite -> Color

func _on_configured() -> void:
	pulse_color = config.get("pulse_color", Color(1.0, 0.8, 0.8, 1.0))
	pulse_rate = config.get("pulse_rate", 2.0)

func on_hover_start(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
	_start_pulse(gamepiece)

func on_hover_end(gamepiece: Gamepiece, tracker: UIRegistry.UIStateTracker) -> void:
	_stop_pulse(gamepiece)

func _start_pulse(gamepiece: Gamepiece) -> void:
	# Stop any existing pulse
	_stop_pulse(gamepiece)
	
	# Store original colors if not already stored
	if not _original_colors.has(gamepiece):
		_original_colors[gamepiece] = SpriteUtils.store_sprite_colors(gamepiece)
	
	var original_colors = _original_colors[gamepiece]
	
	# Create pulse tween
	var tween = gamepiece.create_tween()
	tween.set_loops()  # Infinite loop
	_active_pulses[gamepiece] = tween
	
	# Calculate pulse duration from rate
	var pulse_duration = 1.0 / pulse_rate
	
	# Animate to pulse color then back to original
	SpriteUtils.tween_sprites_to_color(gamepiece, tween, pulse_color, pulse_duration / 2.0)
	SpriteUtils.tween_sprites_to_colors(gamepiece, tween, original_colors, pulse_duration / 2.0)

func _stop_pulse(gamepiece: Gamepiece) -> void:
	if _active_pulses.has(gamepiece):
		var tween = _active_pulses[gamepiece]
		if is_instance_valid(tween):
			tween.kill()
		_active_pulses.erase(gamepiece)
	
	# Restore original colors
	if _original_colors.has(gamepiece):
		SpriteUtils.restore_sprite_colors(gamepiece, _original_colors[gamepiece])
		_original_colors.erase(gamepiece)