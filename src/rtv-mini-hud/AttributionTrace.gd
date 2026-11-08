extends RefCounted
# Optional local diagnostics only. No names, paths, positions, save data, network,
# extra hooks, native calls or file writes. Godot's existing log/capture retains it.
const Reader := preload("res://rtv-mini-hud/TimerReader.gd")
const MAX_RECORDS := 2048
const PREFIX := "[Mini HUD Trace] "
var enabled := false
var emitted := 0

func active() -> bool:
	return enabled and emitted < MAX_RECORDS

func configure(value: bool) -> void:
	if value == enabled:
		return
	if value:
		enabled = true
		record("enabled", {"budget_remaining": MAX_RECORDS - emitted, "schema": 1})
	else:
		record("disabled", {})
		enabled = false
	# Toggling never replenishes the process budget.

func record(event: String, fields: Dictionary) -> int:
	if not active():
		return 0
	emitted += 1
	var row := fields.duplicate()
	row["event"] = event
	row["seq"] = emitted
	row["ms"] = Time.get_ticks_msec()
	_write(row)
	if emitted == MAX_RECORDS:
		_write({"event": "limit", "seq": emitted + 1, "ms": Time.get_ticks_msec(),
			"reason": "process_budget_exhausted", "max_records": MAX_RECORDS})
	return emitted

func _write(row: Dictionary) -> void:
	print(PREFIX + JSON.stringify(row))

static func identity(value) -> int:
	return value.get_instance_id() if value is Object and is_instance_valid(value) else 0

static func number(value):
	if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)):
		return value
	return null

static func target_state(target) -> Dictionary:
	var variant = Reader.property(target, &"variant") if target is Object else null
	var sensor = Reader.property(target, &"sensor") if target is Object else null
	var dead = Reader.property(target, &"dead") if target is Object else null
	return {"target": identity(target),
		"health": number(Reader.property(target, &"health")) if target is Object else null,
		"dead": dead if typeof(dead) == TYPE_BOOL else null,
		"faction": number(Reader.property(variant, &"faction")) if variant is Object else null,
		"sensor": number(Reader.property(sensor, &"type")) if sensor is Object else null}

static func attacker_state(attacker, player) -> Dictionary:
	var kind := "none_or_freed"
	if attacker is Object and is_instance_valid(attacker):
		kind = "other"
		if attacker is Node:
			if attacker == player and attacker.is_in_group("Player"):
				kind = "current_player"
			elif attacker.is_in_group("Nomad"):
				kind = "nomad_id"
			elif attacker.is_in_group("AI"):
				kind = "ai_id"
			elif attacker.is_in_group("Player"):
				kind = "other_player_id"
	return {"attacker": identity(attacker), "attacker_type": kind,
		"current_player": identity(player),
		"player_match": identity(player) != 0 and attacker == player}
