extends RefCounted
# Native Time-slot eligibility, verified on Steam build 25837777.
# Read attachment rather than Item.equipped, which is also set during drag hover.
const Reader := preload("res://rtv-mini-hud/TimerReader.gd")

static func equipped(scene: Node) -> bool:
	if not is_instance_valid(scene) or scene.is_queued_for_deletion() or not scene.is_inside_tree():
		return false
	var slot := scene.get_node_or_null("Core/UI/Interface/Equipment/Time")
	if not is_instance_valid(slot) or slot.is_queued_for_deletion() or slot.get_child_count() != 1:
		return false
	var item := slot.get_child(0)
	if not is_instance_valid(item) or item.is_queued_for_deletion() or item.get_parent() != slot:
		return false
	var slot_data = Reader.property(item, &"slotData")
	var item_data = Reader.property(slot_data, &"itemData") if slot_data is Object else null
	if not item_data is Object or not is_instance_valid(item_data):
		return false
	var file = Reader.property(item_data, &"file")
	var slots = Reader.property(item_data, &"slots")
	# Native DisplayTime accepts all Time-slot items; Tactical only adds a weekday.
	return file is String and not file.is_empty() and slots is Array and slots.has("Time")
