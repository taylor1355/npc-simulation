extends Node

## Central registry for tracking all entities (NPCs and Items) in the game.
## This prevents "freed instance" crashes by ensuring all entity references go through
## the registry, which automatically cleans up when entities are destroyed.

# Core storage - entity_id -> GamepieceController
var _entities: Dictionary[String, GamepieceController] = {}

func _ready() -> void:
	# Listen for entity lifecycle events
	EventBus.gamepiece_destroyed.connect(_on_gamepiece_destroyed)

func register(controller: GamepieceController) -> void:
	# Defer registration to ensure entity_id is set
	call_deferred("_complete_registration", controller)

func _complete_registration(controller: GamepieceController) -> void:
	if not is_instance_valid(controller):
		return
		
	var entity_id = controller.get_entity_id()
	if entity_id.is_empty():
		push_error("Cannot register controller without entity_id")
		return
		
	_entities[entity_id] = controller
	
	# Backup cleanup in case event doesn't fire
	if not controller.tree_exited.is_connected(_on_entity_freed.bind(entity_id)):
		controller.tree_exited.connect(_on_entity_freed.bind(entity_id), CONNECT_ONE_SHOT)

func unregister(entity_id: String) -> void:
	_entities.erase(entity_id)

func get_entity(entity_id: String) -> GamepieceController:
	return _entities.get(entity_id)

func entity_exists(entity_id: String) -> bool:
	return _entities.has(entity_id)

func _on_gamepiece_destroyed(event: GamepieceEvents.DestroyedEvent) -> void:
	unregister(event.gamepiece.entity_id)

func _on_entity_freed(entity_id: String) -> void:
	unregister(entity_id)
