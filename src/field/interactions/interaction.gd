class_name Interaction extends RefCounted

const BidType = preload("res://src/field/interactions/interaction_bid.gd").BidType

var name: String
var description: String
var needs_filled: Array[Needs.Need]  # Needs this interaction will increase
var needs_drained: Array[Needs.Need] # Needs this interaction will decrease
var duration: float = 0.0
var requires_adjacency: bool = true

signal start_request(request: InteractionBid)
signal cancel_request(request: InteractionBid)


func _init(_name: String, _description: String, _fills: Array[Needs.Need] = [], _drains: Array[Needs.Need] = [], _duration: float = 0.0, _requires_adjacency: bool = true):
	name = _name
	description = _description
	needs_filled = _fills
	needs_drained = _drains
	duration = _duration
	requires_adjacency = _requires_adjacency


func can_start_with(npc: NpcController, item: ItemController) -> bool:
	# Basic validation - can be overridden by specific interaction types
	if requires_adjacency:
		var npc_cell = npc._gamepiece.cell
		var item_cell = item._gamepiece.cell
		var distance = abs(npc_cell.x - item_cell.x) + abs(npc_cell.y - item_cell.y)
		return distance <= 1
	return true


func create_start_bid(npc: NpcController) -> InteractionBid:
	return _create_bid(BidType.START, npc)


func create_cancel_bid(npc: NpcController) -> InteractionBid:
	return _create_bid(BidType.CANCEL, npc)


func _create_bid(bid_type: BidType, npc: NpcController) -> InteractionBid:
	return InteractionBid.new(self, bid_type, npc)

# Serialization method for backend communication
## Converts this interaction to a dictionary for serialization
## Note: needs_filled and needs_drained are converted from enums to strings
func to_dict() -> Dictionary[String, Variant]:
	return {
		"name": name,
		"description": description,
		"needs_filled": needs_filled.map(func(need: Needs.Need) -> String: return Needs.get_display_name(need)),
		"needs_drained": needs_drained.map(func(need: Needs.Need) -> String: return Needs.get_display_name(need))
	}
