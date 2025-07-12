class_name SpriteColorManager extends RefCounted

## Manages sprite color modifications from multiple sources to prevent conflicts.
## Each source can apply a color modification, and the manager ensures proper
## restoration when modifications are removed.

# Dictionary of entity_id -> Dictionary of source_id -> color
static var _color_modifications: Dictionary = {}  # String -> Dictionary[String, Color]

# Dictionary of entity_id -> original color data
static var _original_colors: Dictionary = {}  # String -> Dictionary

## Apply a color modification from a specific source
static func apply_color(gamepiece: Gamepiece, source_id: String, color: Color) -> void:
	if not gamepiece or gamepiece.entity_id.is_empty():
		return
	
	var entity_id = gamepiece.entity_id
	
	# Store original colors if this is the first modification
	if not _original_colors.has(entity_id):
		_original_colors[entity_id] = SpriteUtils.store_sprite_colors(gamepiece)
	
	# Initialize modifications dict for this entity if needed
	if not _color_modifications.has(entity_id):
		_color_modifications[entity_id] = {}
	
	# Store this modification
	_color_modifications[entity_id][source_id] = color
	
	# Apply the blended color from all active modifications
	var blended_color = _calculate_blended_color(entity_id)
	SpriteUtils.apply_color_to_sprites(gamepiece, blended_color)

## Remove a color modification from a specific source
static func remove_color(gamepiece: Gamepiece, source_id: String) -> void:
	if not gamepiece or gamepiece.entity_id.is_empty():
		return
	
	var entity_id = gamepiece.entity_id
	
	if not _color_modifications.has(entity_id):
		return
	
	# Remove this source's modification
	_color_modifications[entity_id].erase(source_id)
	
	# If no more modifications, restore original
	if _color_modifications[entity_id].is_empty():
		if _original_colors.has(entity_id):
			SpriteUtils.restore_sprite_colors(gamepiece, _original_colors[entity_id])
			_original_colors.erase(entity_id)
		_color_modifications.erase(entity_id)
	else:
		# Apply the blended color from remaining modifications
		var blended_color = _calculate_blended_color(entity_id)
		SpriteUtils.apply_color_to_sprites(gamepiece, blended_color)

## Clean up all modifications for an entity (e.g., when it's freed)
static func cleanup_entity(entity_id: String) -> void:
	if entity_id.is_empty():
		return
	
	# Remove all modification records
	_color_modifications.erase(entity_id)
	_original_colors.erase(entity_id)

## Check if an entity has any active color modifications
static func has_modifications(entity_id: String) -> bool:
	return _color_modifications.has(entity_id) and not _color_modifications[entity_id].is_empty()

## Debug: Get all active modifications for an entity
static func get_modifications(entity_id: String) -> Dictionary:
	if _color_modifications.has(entity_id):
		return _color_modifications[entity_id]
	return {}

## Calculate the blended color from all active modifications
static func _calculate_blended_color(entity_id: String) -> Color:
	if not _color_modifications.has(entity_id) or _color_modifications[entity_id].is_empty():
		return Color.WHITE
	
	var colors = _color_modifications[entity_id].values()
	if colors.size() == 1:
		return colors[0]
	
	# Multiplicative blending - works well for tints
	var result = Color.WHITE
	for color in colors:
		result *= color
	
	# Ensure alpha doesn't get too low
	result.a = max(result.a, 0.8)
	
	return result