extends RefCounted
# UI sampling uses monotonic time; game time never drives redraw scheduling.
const INTERVAL_USEC := 250000
var _next_usec := 0
func reset() -> void:
	_next_usec = 0
func due(now_usec: int) -> bool:
	if now_usec < _next_usec:
		return false
	_next_usec = now_usec + INTERVAL_USEC
	return true
