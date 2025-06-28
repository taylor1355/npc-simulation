class_name ItemController extends GamepieceController

const GROUP_NAME: = "_ITEM_CONTROLLER_GROUP"

var current_interaction: Interaction = null
var interacting_npc: NpcController = null
var interaction_time: float = 0.0

func _ready() -> void:
	super._ready()
	add_to_group(GROUP_NAME)

func get_entity_type() -> String:
	return "item"

func add_component_node(component: GamepieceComponent) -> void:
	super.add_component_node(component)
	
	# Handle item-specific component setup
	if component is ItemComponent:
		component.interaction_finished.connect(_on_interaction_finished)

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

func handle_interaction_bid(request: InteractionBid) -> void:
	request = request as InteractionBid
	
	# Handle CANCEL requests for existing interactions
	if request.bid_type == InteractionBid.BidType.CANCEL:
		if current_interaction and current_interaction.name == request.interaction_name:
			request.interaction = current_interaction
			# Accept the cancel request
			request.accepted.connect(
				func():
					# End the interaction using the lifecycle method
					current_interaction._on_end({"bid": request})
					_on_interaction_finished(current_interaction.name, {})
			)
			request.accept()
		else:
			request.reject("No matching interaction to cancel")
		return
	
	# Handle START requests
	if current_interaction == null:
		# Get the factory for this interaction
		var factory = interaction_factories.get(request.interaction_name, null)
		if not factory:
			request.reject("Interaction factory not found")
			return

		# Create the interaction from the factory
		var interaction = factory.create_interaction({"requester": request.bidder, "target": self})
		request.interaction = interaction

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
				# Add participant before starting interaction
				interaction.add_participant(request.bidder)
				interaction._on_start({"bid": request})
		)

		# Accept the bid since validation passed
		request.accept()
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

# Override base class method to handle item-specific behavior
func _on_component_interaction_finished(interaction_name: String, payload: Dictionary) -> void:
	_on_interaction_finished(interaction_name, payload)

# get_available_interactions() is now inherited from GamepieceController
