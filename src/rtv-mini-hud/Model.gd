extends RefCounted
# Pure presentation/visibility policy. No game state or wall-clock estimation.
const BLOCKING_FLAGS := [
	"menu", "shelter", "settings", "interface", "freeze", "isDead",
	"isTransitioning", "isCaching", "isSleeping", "isTrading", "transition",
	"decor", "flycam", "tutorial",
]

const MODE_TOGGLE := "toggle"
const MODE_ALWAYS_ON := "always_on"

var requested := false
var enabled := true
var display_mode := MODE_TOGGLE

func set_display_mode(mode: String) -> void:
	var next_mode := MODE_ALWAYS_ON if mode == MODE_ALWAYS_ON else MODE_TOGGLE
	if display_mode != next_mode:
		display_mode = next_mode
		# Never revive an old Toggle choice after a mode switch.
		reset()

func allowed(context: Dictionary) -> bool:
	if not enabled or not context.get("ready", false) or context.get("paused", true):
		return false
	for flag in BLOCKING_FLAGS:
		if context.get(flag, true):
			return false
	return true

func toggle(context: Dictionary) -> bool:
	if display_mode != MODE_TOGGLE or not allowed(context):
		return false
	requested = not requested
	return true

func visible_in(context: Dictionary) -> bool:
	return (display_mode == MODE_ALWAYS_ON or requested) and allowed(context)

func reset() -> void:
	requested = false

static func countdown(seconds: float) -> String:
	# Match vanilla's integer truncation; 00:00 never asserts a completed reset.
	var whole := maxi(0, int(seconds))
	return "%02d:%02d" % [whole / 60, whole % 60]

static func trader_cell(rows: Array) -> Dictionary:
	var cell := {"status": "unavailable", "value": "--:--", "icon": "user"}
	if rows.is_empty():
		return cell
	var values := PackedStringArray()
	for row in rows:
		match row.get("status", "unavailable"):
			"running", "paused":
				values.append(countdown(row.seconds))
			"inactive":
				values.append("INACTIVE")
			"pending":
				values.append("WAIT")
			_:
				values.append("--:--")
	cell.status = rows[0].get("status", "unavailable") if rows.size() == 1 else "multiple"
	if rows.size() > 1:
		# Preserve all current-map observations; never select an unexplained minimum.
		for i in range(rows.size()):
			if rows[i].get("status") == "paused":
				values[i] = "PAUSED"
	cell.value = "\n".join(values)
	return cell
