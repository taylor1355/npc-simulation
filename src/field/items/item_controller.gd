@tool
class_name ItemController extends GamepieceController

const GROUP_NAME: = "_ITEM_CONTROLLER_GROUP"

var interactions: Dictionary = {}
var current_interaction: Interaction = null
var interacting_npc: NpcController = null
var interaction_time: float = 0.0

signal interaction_finished(interaction_name: String, npc: NpcController, payload: Dictionary)

func _ready() -> void:
    super._ready()
    if not Engine.is_editor_hint():
        add_to_group(GROUP_NAME)

func add_component_node(component: GamepieceComponent) -> void:
    super.add_component_node(component)
    
    # Handle item-specific component setup
    if component is ItemComponent:
        component.interaction_finished.connect(_on_interaction_finished)
        
        # Collect interactions from component
        var expected_num_interactions = len(interactions) + len(component.interactions)
        interactions.merge(component.interactions)
        if expected_num_interactions != len(interactions):
            push_error("Duplicate interactions found in component: %s" % component.get_component_name())

func add_component(config: ItemComponentConfig) -> void:
    # Validate config
    if not config._validate():
        push_error("Invalid component configuration")
        return
        
    # Create component instance
    var component = config.component_script.new()
    
    # Configure properties
    for key in config.properties:
        if not key in component:
            push_error("Invalid property '%s' for component" % key)
            component.free()
            return
        component.set(key, config.properties[key])
    
    # Add to scene tree and register component
    add_component_node(component)

func _process(delta: float) -> void:
    if current_interaction:
        interaction_time += delta

func request_interaction(request: InteractionRequest) -> void:
    request = request as InteractionRequest
    if current_interaction == null:
        request.item_controller = self

        var interaction = interactions.get(request.interaction_name, null)
        if not interaction:
            request.reject("Interaction not found")
            return

        if request.request_type == InteractionRequest.RequestType.START:
            interaction.start_request.emit(request)
        elif request.request_type == InteractionRequest.RequestType.CANCEL:
            interaction.cancel_request.emit(request)
        else:
            request.reject("Invalid request type")
            return

        # may need to defer the status check, so that the request handler can have time to finish
        if request.status == InteractionRequest.Status.ACCEPTED:
            current_interaction = interaction
            interacting_npc = request.npc_controller
            interaction_time = 0.0
    else:
        request.reject("An interaction is already in progress")

func _on_interaction_finished(interaction_name: String, payload: Dictionary) -> void:
    interaction_finished.emit(interaction_name, interacting_npc, payload)
    current_interaction = null
    interacting_npc = null
    interaction_time = 0.0
