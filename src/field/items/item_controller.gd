@tool
class_name ItemController extends GamepieceController

const GROUP_NAME: = "_ITEM_CONTROLLER_GROUP"

var interactions: Dictionary[String, Interaction] = {} # interaction name -> Interaction
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
	
	# Configure properties using the component's configure method
	component.configure_properties(config.properties)
	
	# Add to scene tree and register component
	add_component_node(component)

func _process(delta: float) -> void:
	if current_interaction:
		interaction_time += delta

func request_interaction(request: InteractionBid) -> void:
	request = request as InteractionBid
	if current_interaction == null:
		var interaction = interactions.get(request.interaction.name, null)
		if not interaction:
			request.reject("Interaction not found")
			return

		# Validate interaction can start
		if not interaction.can_start_with(request.bidder, self):
			request.reject("Interaction requirements not met")
			return

		# Connect to request status changes
		request.accepted.connect(
			func():
				current_interaction = interaction
				interacting_npc = request.bidder
				interaction_time = 0.0
		)

		if request.bid_type == InteractionBid.BidType.START:
			interaction.start_request.emit(request)
		elif request.bid_type == InteractionBid.BidType.CANCEL:
			interaction.cancel_request.emit(request)
		else:
			request.reject("Invalid request type")
	else:
		request.reject("An interaction is already in progress")

func _on_interaction_finished(interaction_name: String, payload: Dictionary) -> void:
	var npc = interacting_npc  # Store reference before clearing
	
	# Clear interaction state before emitting event
	current_interaction = null
	interacting_npc = null
	interaction_time = 0.0
	
	# Emit event after clearing state
	interaction_finished.emit(interaction_name, npc, payload)
