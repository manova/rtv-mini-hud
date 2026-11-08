extends RefCounted
# The only game-state adapter. Reads live Timer.time_left; never invokes traders.
static func property(object: Object, key: StringName, fallback = null):
	if not is_instance_valid(object):
		return fallback
	for entry in object.get_property_list():
		if entry.name == key:
			return object.get(key)
	return fallback

static func context(data: Object, scene: Node, tree: SceneTree) -> Dictionary:
	var result := {"ready": false, "paused": tree.paused}
	if not is_instance_valid(data) or not is_instance_valid(scene):
		return result
	# All observed flags must exist and remain Boolean. Fail closed on API drift.
	var fields := {}
	for entry in data.get_property_list():
		fields[entry.name] = true
	for flag in preload("res://rtv-mini-hud/Model.gd").BLOCKING_FLAGS:
		var value = data.get(flag) if fields.has(flag) else null
		if typeof(value) != TYPE_BOOL:
			return result
		result[flag] = value
	result.ready = scene.get_node_or_null("Core/UI") != null
	return result

static func sample(trader: Node) -> Dictionary:
	var row := {"name": "Trader", "status": "unavailable", "seconds": 0.0}
	if not is_instance_valid(trader) or not trader.is_inside_tree() or trader.is_queued_for_deletion():
		return row
	var data = property(trader, &"traderData")
	var title = property(data, &"name", "Trader") if is_instance_valid(data) else "Trader"
	if title is String and not title.is_empty():
		row.name = title
	var timer = property(trader, &"timer")
	if not is_instance_valid(timer) or not timer is Timer or not timer.is_inside_tree():
		return row
	if timer.is_queued_for_deletion() or not trader.is_ancestor_of(timer):
		return row
	var seconds: float = timer.time_left
	if not is_finite(seconds) or seconds < 0.0:
		return row
	row.seconds = seconds
	if timer.is_stopped() or seconds <= 0.0:
		row.status = "pending"
	elif timer.paused or not timer.can_process() or (Engine.time_scale <= 0.0 and not timer.ignore_time_scale):
		row.status = "paused"
	elif not trader.can_process():
		row.status = "inactive"
	else:
		row.status = "running"
	return row

static func read(tree: SceneTree, scene: Node) -> Array:
	var rows: Array = []
	if not is_instance_valid(scene):
		return rows
	for trader in tree.get_nodes_in_group("Trader"):
		# No carried-over nodes from the previous scene or retained save slots.
		if scene.is_ancestor_of(trader) and not trader.is_queued_for_deletion():
			rows.append(sample(trader))
	rows.sort_custom(func(a, b): return str(a.name).naturalnocasecmp_to(str(b.name)) < 0)
	return rows
