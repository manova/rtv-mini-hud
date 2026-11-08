extends RefCounted
# Honest fallback before observation is verified or after certainty is lost.
# No passive native player-kill statistic exists in the inspected current build.
static func read() -> Dictionary:
	return {"status": "unavailable", "value": "N/A", "icon": "skull"}
