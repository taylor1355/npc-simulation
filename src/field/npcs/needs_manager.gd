class_name NeedsManager
extends RefCounted

signal need_changed(need_name: String, new_value: float)

var _needs: Dictionary[Needs.Need, float] = {}
var _decay_rate: float = 1.0

func _init(decay_rate: float = 1.0):
	_decay_rate = decay_rate
	for need in Needs.Need.values():
		_needs[need] = Needs.MAX_VALUE

func update_need(need: Needs.Need, delta: float) -> void:
	_needs[need] += delta
	_needs[need] = clamp(_needs[need], 0.0, Needs.MAX_VALUE)
	need_changed.emit(Needs.get_display_name(need), _needs[need])

func process_decay(delta_time: float) -> void:
	for need in Needs.Need.values():
		update_need(need, -_decay_rate * delta_time)

func get_all_needs() -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	for need in Needs.Need.values():
		result[Needs.get_display_name(need)] = _needs[need]
	return result

func reemit_all_needs() -> void:
	for need in Needs.Need.values():
		need_changed.emit(Needs.get_display_name(need), _needs[need])

func set_decay_rate(rate: float) -> void:
	_decay_rate = rate
