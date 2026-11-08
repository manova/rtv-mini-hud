extends RefCounted
# Read-only current-build adapter. Never derive gameplay night from clock text.
const Reader := preload("res://rtv-mini-hud/TimerReader.gd")
var _identity := 0
var _world_time := -1.0
var _simulation_time := -1.0
var _fresh_updates := 0

func reset() -> void:
	_identity = 0
	_world_time = -1.0
	_simulation_time = -1.0
	_fresh_updates = 0

static func unavailable() -> Dictionary:
	return {"status": "unavailable", "value": "--:--", "icon": "question"}

static func format_time(raw: float) -> String:
	# Current native Interface.DisplayTime convention, including its unusual carry.
	var hours := int(raw / 100.0)
	var minutes := (int(raw) % 100) / 5 * 5
	if minutes >= 60:
		minutes = 0
		hours += 1
	return "%02d:%02d" % [hours % 24, minutes]

func observe(snapshot: Dictionary) -> Dictionary:
	# Separate observations make update ordering, stale caches and time jumps testable.
	if not snapshot.get("ready", false):
		reset()
		return unavailable()
	var identity: int = snapshot.get("identity", 0)
	var phase = snapshot.get("phase")
	var world_time = snapshot.get("world_time")
	var simulation_time = snapshot.get("simulation_time")
	var simulate = snapshot.get("simulate")
	if identity == 0 or typeof(phase) != TYPE_INT or phase < 1 or phase > 4 \
			or not _valid_time(world_time) or not _valid_time(simulation_time) \
			or typeof(simulate) != TYPE_BOOL:
		reset()
		return unavailable()
	if identity != _identity:
		reset()
		_identity = identity
	# World publishes TOD before copying Simulation.time. Require two observed
	# world updates after every invalidation, then read the actually published TOD.
	if _world_time < 0.0:
		_world_time = world_time
		_simulation_time = simulation_time
		return unavailable()
	var world_delta: float = world_time - _world_time
	var simulation_delta: float = simulation_time - _simulation_time
	if world_delta < 0.0 or world_delta > 1.0 or simulation_delta < 0.0 \
			or simulation_delta > 1.0 or absf(simulation_time - world_time) > 1.0:
		_fresh_updates = 0
	elif world_delta > 0.0:
		_fresh_updates = mini(2, _fresh_updates + 1)
	_world_time = world_time
	_simulation_time = simulation_time
	if _fresh_updates < 2:
		return unavailable()
	return {
		"status": "running" if simulate else "paused",
		"value": format_time(simulation_time),
		"icon": "moon" if phase == 4 else "sun",
		"phase": phase,
	}

static func _valid_time(value) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) \
		and is_finite(float(value)) and value >= 0.0 and value < 2400.0

func read(scene: Node, data: Object, simulation: Node, allowed: bool) -> Dictionary:
	if not allowed or not is_instance_valid(scene) or not is_instance_valid(simulation):
		return observe({})
	var world := scene.get_node_or_null("World")
	if not is_instance_valid(world) or world.is_queued_for_deletion() or not world.can_process() or not world.is_processing():
		return observe({})
	var simulate = Reader.property(simulation, &"simulate")
	if typeof(simulate) != TYPE_BOOL:
		return observe({})
	# Nonzero World.tick needs a different freshness contract. Fail closed.
	var ready: bool = Reader.property(world, &"enable") == true \
		and Reader.property(world, &"shelter") == false \
		and Reader.property(world, &"intro") == false \
		and Reader.property(world, &"tick") == 0.0 \
		and not simulation.is_queued_for_deletion() and simulation.can_process()
	return observe({
		"ready": ready, "identity": world.get_instance_id(),
		"phase": Reader.property(data, &"TOD"),
		"world_time": Reader.property(world, &"time"),
		"simulation_time": Reader.property(simulation, &"time"),
		"simulate": simulate and simulation.is_processing() and Engine.time_scale > 0.0,
	})
