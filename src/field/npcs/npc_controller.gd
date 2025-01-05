class_name NpcController extends GamepieceController

const GROUP_NAME: = "_NPC_CONTROLLER_GROUP"

var is_active: = false:
	set(value):
		is_active = value
		
		# set_process(is_active)
		# set_physics_process(is_active)
		set_process_input(is_active)
		set_process_unhandled_input(is_active)

# needs
# TODO: eventually refactor each need to be an object so each need can have an update fn, its own decay rate, etc.
var decay_rate: float = 0.0 # for testing, just set to a random value between 1 and 5
var MAX_NEED_VALUE: = 100.0
var NEED_IDS = [
	"hunger",
	"hygiene",
	"fun",
	"energy",
]
var needs = {}

# pathfinding
var destination : Vector2i
var movement_locked: bool = false

# State machine
enum NPCState {
	IDLE,
	MOVING_TO_ITEM,
	INTERACTING,
	WANDERING
}

# Idle timing (seconds)
const MOVEMENT_COOLDOWN = 0.75  # How long to idle after movement is unlocked 
var idle_timer: float = 0.0  # Time left to idle

var current_state: NPCState = NPCState.IDLE
var current_interaction: Interaction = null

@onready var _vision_manager: VisionManager = $VisionArea as VisionManager

signal need_changed(need_id: String, new_value: float)


################
### Built-in ###
################
func _ready() -> void:
	super._ready()

	set_process(true)
	set_physics_process(false)

	if not Engine.is_editor_hint():
		add_to_group(GROUP_NAME)
		
		# Forward local signals to the corresponding FieldEvents
		need_changed.connect(
			func(need_id: String, new_value: float): FieldEvents.npc_need_changed.emit(_gamepiece, need_id, new_value)
		)

		for need_id in NEED_IDS:
			needs[need_id] = MAX_NEED_VALUE
			need_changed.emit(need_id, needs[need_id])
		decay_rate = randf_range(1, 5)
	
		# Wait a frame for the gameboard and physics engine to be fully setup. Once the physics 
		# engine is ready, its state may be queried to setup the pathfinder.
		await get_tree().process_frame
		decide_behavior.call_deferred()


func _process(delta: float) -> void:
	# Update needs
	for need_id in NEED_IDS:
		update_need(need_id, -decay_rate * delta)
	
	# Handle idle timer if we're idling
	if current_state == NPCState.IDLE and idle_timer > 0:
		idle_timer -= delta
		if idle_timer <= 0:
			decide_behavior()
	

func set_is_paused(paused: bool) -> void:
	super.set_is_paused(paused)
	# set_process(!paused)
	# set_physics_process(!paused)
	

#############
### Needs ###
#############
func update_need(need_id: String, delta: float) -> void:
	if not needs.has(need_id):
		print("need_id not found: ", need_id)
		return
		
	var old_value = needs[need_id]
	needs[need_id] += delta
	needs[need_id] = clamp(needs[need_id], 0, MAX_NEED_VALUE)
	need_changed.emit(need_id, needs[need_id])
	
	# Trigger behavior update at energy thresholds
	if need_id == "energy":
		if (old_value < MAX_NEED_VALUE and needs[need_id] >= MAX_NEED_VALUE) or \
		   (old_value > 0 and needs[need_id] <= 0):
			decide_behavior()


func reemit_needs() -> void:
	for need_id in NEED_IDS:
		need_changed.emit(need_id, needs[need_id])


###################
### Pathfinding ###
###################
func set_new_destination(new_destination = null) -> void:
	if movement_locked:
		return

	if not new_destination:
		var bounds : Rect2i = _gamepiece.gameboard.boundaries
		destination = bounds.position + Vector2i(
			randi_range(0, bounds.size.x - 1),
			randi_range(0, bounds.size.y - 1),
		)
	else:
		destination = new_destination as Vector2i

	FieldEvents.gamepiece_path_set.emit.call_deferred(_gamepiece, destination)
	travel_to_cell(destination, true)


func set_movement_locked(locked: bool) -> void:
	if movement_locked and not locked:
		current_state = NPCState.IDLE
		idle_timer = MOVEMENT_COOLDOWN
	movement_locked = locked


######################
### Placeholder AI ###
######################
func decide_behavior() -> void:
	# First check if we need to stop sitting, regardless of movement lock
	if current_interaction and current_interaction.name == "sit" and needs["energy"] >= MAX_NEED_VALUE:
		var cancel_request = current_interaction.create_cancel_request(self)
		current_interaction.cancel_request.emit(cancel_request)
		return
		
	# Then check movement lock and idle timer
	if movement_locked or (current_state == NPCState.IDLE and idle_timer > 0):
		return
		
	# If currently interacting, continue interaction
	if current_interaction:
		current_state = NPCState.INTERACTING
		return

	# Check visible items
	var seen_items: Array = _vision_manager.get_items_by_distance()
	if seen_items.is_empty():
		current_state = NPCState.WANDERING
		set_new_destination()
		return
	
	# Try to interact with each visible item
	for item in seen_items:
		if not item.interactions or item.current_interaction:
			continue

		# Skip chairs if energy is high
		if item.interactions.has("sit") and needs["energy"] >= 0.5 * MAX_NEED_VALUE:
			continue
			
		var distance = _gamepiece.cell.distance_to(item._gamepiece.cell)
		if distance > 1:
			current_state = NPCState.MOVING_TO_ITEM
			set_new_destination(item._gamepiece.cell)
			return
			
		# Choose interaction
		var interaction = null
		if needs["energy"] < 0.5 * MAX_NEED_VALUE and item.interactions.has("sit"):
			interaction = item.interactions["sit"]
		else:
			interaction = item.interactions.values()[0]
			
		# Request interaction
		var interaction_request = interaction.create_start_request(self)
		interaction_request.accepted.connect(
			func():
				current_interaction = interaction
				item.interaction_finished.connect(_on_interaction_finished)
				current_state = NPCState.INTERACTING
		)
		interaction_request.rejected.connect(
			func(_reason):
				current_interaction = null
		)
		item.request_interaction.call_deferred(interaction_request)
		return
	
	# No suitable items found
	current_state = NPCState.WANDERING
	set_new_destination()


################
### Handlers ###
################
func _on_interaction_finished(_interaction_name: String, npc: NpcController, _payload: Dictionary) -> void:
	if npc == self:
		current_interaction = null
		decide_behavior()
	
	
func _on_gamepiece_arrived() -> void:
	super._on_gamepiece_arrived()
	decide_behavior()


func _on_focused_gamepiece_changed(new_focused_gamepiece: Gamepiece) -> void:
	if new_focused_gamepiece == _gamepiece:
		reemit_needs()
