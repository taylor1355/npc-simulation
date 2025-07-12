class_name UILink extends RefCounted

## Represents a clickable link in UI text with type-safe construction.
## Links follow the format: [url=target_type://target_id]link_text[/url]

enum TargetType {
	ENTITY,      # Focus on an entity
	INTERACTION, # Open interaction panel
}

var target_type: TargetType
var target_id: String
var link_text: String
var color: Color = Color.CORNFLOWER_BLUE

func _init(type: TargetType, id: String, text: String) -> void:
	target_type = type
	target_id = id
	link_text = text

## Create a link to focus on an entity
static func entity(entity_id: String, display_name: String) -> UILink:
	return UILink.new(TargetType.ENTITY, entity_id, display_name)

## Create a link to open an interaction panel
static func interaction(interaction_id: String, display_text: String = "View") -> UILink:
	return UILink.new(TargetType.INTERACTION, interaction_id, display_text)

## Convert to BBCode string
func to_bbcode() -> String:
	var type_str = _target_type_to_string(target_type)
	var color_hex = "#" + color.to_html(false)
	return "[url=%s://%s][color=%s]%s[/color][/url]" % [type_str, target_id, color_hex, link_text]

## Parse a link reference into a UILink
static func parse(link_ref: String) -> UILink:
	var parts = link_ref.split("://", false, 1)
	if parts.size() != 2:
		return null
	
	var type = _string_to_target_type(parts[0])
	if type == -1:
		return null
		
	return UILink.new(type, parts[1], "")

## Get target type from string
static func _string_to_target_type(type_str: String) -> TargetType:
	match type_str:
		"entity":
			return TargetType.ENTITY
		"interaction":
			return TargetType.INTERACTION
		_:
			return -1

## Convert target type to string
static func _target_type_to_string(type: TargetType) -> String:
	match type:
		TargetType.ENTITY:
			return "entity"
		TargetType.INTERACTION:
			return "interaction"
		_:
			return ""

## Execute the link's action
func execute() -> void:
	match target_type:
		TargetType.ENTITY:
			_execute_entity_link()
		TargetType.INTERACTION:
			_execute_interaction_link()

func _execute_entity_link() -> void:
	var gamepiece = _find_gamepiece_by_entity_id(target_id)
	if not gamepiece:
		push_warning("Entity link references non-existent entity: " + target_id)
		return
	
	# Focus on the entity
	var event = GamepieceEvents.create_focused(gamepiece)
	EventBus.dispatch(event)

func _execute_interaction_link() -> void:
	var interaction = InteractionRegistry.get_interaction_by_id(target_id)
	if not interaction:
		push_warning("Interaction link references non-existent interaction: " + target_id)
		return
	
	# Use UIElementProvider singleton to display the panel
	UIElementProvider.display_interaction_panel(interaction)

func _find_gamepiece_by_entity_id(entity_id: String) -> Gamepiece:
	# TODO: Use EntityRegistry when available
	# TECHNICAL DEBT: This searches through all gamepieces O(n)
	# Should be replaced with EntityRegistry.get_entity(entity_id) once implemented
	
	# Use UIRegistry (which is a Node) to access the scene tree
	var gamepieces = UIRegistry.get_tree().get_nodes_in_group(Globals.GAMEPIECE_GROUP)
	for gamepiece in gamepieces:
		if gamepiece is Gamepiece and gamepiece.entity_id == entity_id:
			return gamepiece
	return null
