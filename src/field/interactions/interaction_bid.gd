class_name InteractionBid extends RefCounted

enum BidType {
	START,
	CANCEL
}

enum BidStatus {
	PENDING,
	ACCEPTED,
	REJECTED
}

var interaction_name: String
var bidder: NpcController
var target: GamepieceController  # The item or NPC being interacted with
var bid_type: BidType
var status: BidStatus
var interaction: Interaction = null  # Created when bid is accepted
var bid_id: String

signal accepted()
signal rejected(reason: String)


func _init(_interaction_name: String, _bid_type: BidType, _bidder: NpcController, _target: GamepieceController):
	interaction_name = _interaction_name
	bid_type = _bid_type
	bidder = _bidder
	target = _target
	status = BidStatus.PENDING
	bid_id = IdGenerator.generate_bid_id()


func accept():
	status = BidStatus.ACCEPTED
	accepted.emit()
	

func reject(reason: String):
	status = BidStatus.REJECTED
	rejected.emit(reason)
