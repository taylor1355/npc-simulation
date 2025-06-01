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

var interaction: Interaction
var bidder: NpcController
var bid_type: BidType
var status: BidStatus

signal accepted()
signal rejected(reason: String)


func _init(_interaction: Interaction, _bid_type: BidType, _bidder: NpcController):
	interaction = _interaction
	bid_type = _bid_type
	bidder = _bidder
	status = BidStatus.PENDING


func accept():
	status = BidStatus.ACCEPTED
	accepted.emit()
	

func reject(reason: String):
	status = BidStatus.REJECTED
	rejected.emit(reason)
