class_name SpriteUtils

## Utility class for common sprite manipulation operations used by UI behaviors.
## Provides methods for finding sprites, storing/restoring colors, and applying effects.

## Find all Sprite2D nodes in a gamepiece
static func get_sprites(gamepiece: Gamepiece) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	for node in gamepiece.find_children("*", "Sprite2D", true):
		sprites.append(node as Sprite2D)
	return sprites

## Store the current modulate colors of all sprites in a gamepiece
static func store_sprite_colors(gamepiece: Gamepiece) -> Dictionary:
	var colors: Dictionary = {}
	for sprite in get_sprites(gamepiece):
		colors[sprite] = sprite.modulate
	return colors

## Restore sprite colors from a stored dictionary
static func restore_sprite_colors(gamepiece: Gamepiece, colors: Dictionary) -> void:
	for sprite in get_sprites(gamepiece):
		if colors.has(sprite):
			sprite.modulate = colors[sprite]

## Apply a color to all sprites in a gamepiece
static func apply_color_to_sprites(gamepiece: Gamepiece, color: Color) -> void:
	for sprite in get_sprites(gamepiece):
		sprite.modulate = color

## Create a tween that modulates all sprites to a color
static func tween_sprites_to_color(gamepiece: Gamepiece, tween: Tween, color: Color, duration: float) -> void:
	for sprite in get_sprites(gamepiece):
		tween.parallel().tween_property(sprite, "modulate", color, duration)

## Create a tween that restores sprites to their original colors
static func tween_sprites_to_colors(gamepiece: Gamepiece, tween: Tween, colors: Dictionary, duration: float) -> void:
	for sprite in get_sprites(gamepiece):
		if colors.has(sprite):
			tween.parallel().tween_property(sprite, "modulate", colors[sprite], duration)