extends RefCounted
# Optional MCM integration; only this mod's namespaced config may be written.
const Model := preload("res://rtv-mini-hud/Model.gd")
const DEFAULT_X := 92.0
const DEFAULT_Y := 3.0
const MOD_ID := "rtv_mini_hud"
const ACTION := "rtv_mini_hud_toggle"
const CONFIG_DIR := "user://MCM/rtv_mini_hud"
const CONFIG_FILE := CONFIG_DIR + "/config.ini"
const HELPERS := "res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres"

static func defaults() -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("Bool", "enabled", {
		"name": "Enable Mini HUD", "tooltip": "Enable Mini HUD in the selected display mode.",
		"default": true, "value": true, "menu_pos": 1,
	})
	config.set_value("Dropdown", "display_mode", {
		"name": "Display mode",
		"tooltip": "Toggle: use the shortcut. Always on: show automatically during eligible outdoor gameplay; shortcut ignored. Changing modes clears the old toggle choice; returning to Toggle starts hidden.",
		"default": Model.MODE_TOGGLE, "value": Model.MODE_TOGGLE,
		"options": {Model.MODE_TOGGLE: "Toggle", Model.MODE_ALWAYS_ON: "Always on"},
		"menu_pos": 2,
	})
	config.set_value("Keycode", ACTION, {
		"name": "Toggle Mini HUD", "tooltip": "Show or hide Mini HUD in Toggle mode only. Ignored in Always on. Default: F8; saved bindings are preserved.",
		"default": KEY_F8, "default_type": "Key", "type": "Key", "value": KEY_F8,
		"altPressed": false, "controlPressed": false, "metaPressed": false, "shiftPressed": false,
		"menu_pos": 3,
	})
	config.set_value("Bool", "show_trader_timer", {
		"name": "Show trader timer", "tooltip": "Show the current-area trader timer cell. Hiding it compacts the HUD and does not change native trader timers.",
		"default": true, "value": true, "menu_pos": 8,
	})
	config.set_value("Bool", "show_kill_counter", {
		"name": "Show kill counter", "tooltip": "Show verified player kills. Hiding the cell compacts the HUD; tracking continues with the same attribution and reset rules.",
		"default": true, "value": true, "menu_pos": 9,
	})
	config.set_value("Bool", "orange", {
		"name": "Orange trader variant", "tooltip": "Tint only the trader icon and value orange for comparison.",
		"default": false, "value": false, "menu_pos": 10,
	})
	config.set_value("Bool", "cumulative_kills", {
		"name": "Cumulative session kills", "tooltip": "Off: current map visit, reset on reload or death. On: all verified kills since game launch. Neither total is saved.",
		"default": false, "value": false, "menu_pos": 11,
	})
	config.set_value("Bool", "show_without_watch", {
		"name": "Show clock without time equipment", "tooltip": "Off: requires an item equipped in the Time slot, such as a Tactical Watch or Alarm Clock. On: show native time without time equipment.",
		"default": false, "value": false, "menu_pos": 12,
	})
	config.set_value("Bool", "attribution_trace", {
		"name": "Diagnostic kill trace", "tooltip": "Optional local damage attribution log. No combat changes. Stops after 2048 records per game launch; capture after exit. Off for ordinary use.",
		"default": false, "value": false, "menu_pos": 13,
	})
	for option in [
		["scale", "HUD scale (%)", "Size of the compact row.", 100, 65, 180, 5, 4],
		["x", "Horizontal position (%)", "0 = left edge, 100 = right edge. Default position reserves room for the native permadeath icon.", int(DEFAULT_X), 0, 100, 1, 5],
		["y", "Vertical position (%)", "0 = top edge, 100 = bottom edge. Default position reserves room for the native permadeath icon.", int(DEFAULT_Y), 0, 100, 1, 6],
		["opacity", "Backdrop opacity (%)", "Shared dark backdrop; icons and values remain opaque.", 42, 0, 90, 1, 7],
	]:
		config.set_value("Int", option[0], {"name": option[1], "tooltip": option[2],
			"default": option[3], "value": option[3], "minRange": option[4],
			"maxRange": option[5], "step": option[6], "menu_pos": option[7]})
	return config

static func merge_missing(config: ConfigFile) -> bool:
	var changed := false
	var base := defaults()
	for section in base.get_sections():
		for key in base.get_section_keys(section):
			if not config.has_section_key(section, key):
				config.set_value(section, key, base.get_value(section, key))
				changed = true
	# MCM reads each entry's metadata directly. Hydrate every known entry,
	# including value-only older configs, without replacing saved preferences.
	var saved_fields := ["value", "type", "altPressed", "controlPressed", "metaPressed", "shiftPressed"]
	for section in base.get_sections():
		for key in base.get_section_keys(section):
			var entry = config.get_value(section, key)
			if not entry is Dictionary:
				continue
			var expected: Dictionary = base.get_value(section, key)
			for field in expected:
				if field in saved_fields and entry.has(field):
					continue
				if not entry.has(field) or entry[field] != expected[field]:
					entry[field] = expected[field]
					config.set_value(section, key, entry)
					changed = true
			# A missing options list let MCM save an invalid numeric mode. Keep
			# every valid string choice; otherwise use the same Toggle fallback
			# as normalized(), never interpret a corrupt value as an option index.
			if section == "Dropdown" and key == "display_mode" and (typeof(entry.get("value")) != TYPE_STRING or not expected.options.has(entry.get("value"))):
				entry["value"] = expected.default
				config.set_value(section, key, entry)
				changed = true
	return changed

static func _number(config: ConfigFile, key: String, fallback: float, low: float, high: float) -> float:
	var entry = config.get_value("Int", key, {})
	var value = entry.get("value", fallback) if entry is Dictionary else fallback
	if not (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), low, high)

static func normalized(config: ConfigFile) -> Dictionary:
	var orange = config.get_value("Bool", "orange", {})
	var layout := {
		"scale": _number(config, "scale", 100, 65, 180) / 100.0,
		"x": _number(config, "x", DEFAULT_X, 0, 100),
		"y": _number(config, "y", DEFAULT_Y, 0, 100),
		"opacity": _number(config, "opacity", 42, 0, 90) / 100.0,
		"orange": orange is Dictionary and orange.get("value", false) == true,
	}
	# Missing or malformed visibility entries retain the released three-cell HUD.
	for key in ["show_trader_timer", "show_kill_counter"]:
		var option = config.get_value("Bool", key, {})
		layout[key] = option.value if option is Dictionary and typeof(option.get("value")) == TYPE_BOOL else true
	var state := {"enabled": true, "event": InputEventKey.new(), "layout": layout,
		"cumulative_kills": false, "show_without_watch": false, "attribution_trace": false,
		"display_mode": Model.MODE_TOGGLE}
	var mode_entry = config.get_value("Dropdown", "display_mode", {})
	if mode_entry is Dictionary and typeof(mode_entry.get("value")) == TYPE_STRING and mode_entry.value == Model.MODE_ALWAYS_ON:
		state.display_mode = Model.MODE_ALWAYS_ON
	for key in ["cumulative_kills", "show_without_watch", "attribution_trace"]:
		var option = config.get_value("Bool", key, {})
		state[key] = option is Dictionary and typeof(option.get("value")) == TYPE_BOOL and option.value
	state.event.physical_keycode = KEY_F8
	var enabled_entry = config.get_value("Bool", "enabled", {})
	if enabled_entry is Dictionary and typeof(enabled_entry.get("value")) == TYPE_BOOL:
		state.enabled = enabled_entry.value
	var entry = config.get_value("Keycode", ACTION, {})
	if not entry is Dictionary:
		return state
	var key = entry.get("value", KEY_F8)
	if typeof(key) != TYPE_INT or key < 0:
		return state
	var event: InputEventWithModifiers
	if entry.get("type", "Key") == "Mouse":
		if key < MOUSE_BUTTON_LEFT or key > MOUSE_BUTTON_XBUTTON2:
			return state
		var mouse := InputEventMouseButton.new()
		mouse.button_index = key
		event = mouse
	elif entry.get("type", "Key") == "Key":
		var keyboard := InputEventKey.new()
		keyboard.physical_keycode = key # Zero is an intentional unbound shortcut.
		event = keyboard
	else:
		return state
	event.alt_pressed = entry.get("altPressed", false) == true
	event.ctrl_pressed = entry.get("controlPressed", false) == true
	event.meta_pressed = entry.get("metaPressed", false) == true
	event.shift_pressed = entry.get("shiftPressed", false) == true
	state.event = event
	return state

static func shortcut_pressed(event: InputEvent) -> bool:
	if not InputMap.has_action(ACTION):
		return false
	if event.is_action_pressed(ACTION, false, true):
		return true
	# Only tolerate Shift supplied by the game's currently held sprint action.
	# Keep every other modifier exact, including explicitly configured chords.
	if not event is InputEventWithModifiers or not event.shift_pressed:
		return false
	if not InputMap.has_action("sprint") or not Input.is_action_pressed("sprint"):
		return false
	for binding in InputMap.action_get_events("sprint"):
		if not binding is InputEventKey:
			continue
		var code: int = binding.physical_keycode if binding.physical_keycode else binding.keycode
		if code != KEY_SHIFT or binding.ctrl_pressed or binding.alt_pressed or binding.meta_pressed:
			continue
		var without_sprint: InputEventWithModifiers = event.duplicate()
		without_sprint.shift_pressed = false
		return without_sprint.is_action_pressed(ACTION, false, true)
	return false

static func install(owner: Node) -> void:
	var config := defaults()
	# No config is written when MCM is absent.
	if ResourceLoader.exists(HELPERS):
		var helper = load(HELPERS)
		if helper != null and helper.has_method("RegisterConfiguration"):
			if FileAccess.file_exists(CONFIG_FILE):
				config = ConfigFile.new()
				if config.load(CONFIG_FILE) != OK:
					push_warning("[Mini HUD] Config unreadable; using defaults without overwriting.")
					owner.apply_config(defaults())
					return
				if merge_missing(config) and config.save(CONFIG_FILE) != OK:
					push_warning("[Mini HUD] New MCM settings could not be saved; using them for this session.")
			else:
				var error := DirAccess.make_dir_recursive_absolute(CONFIG_DIR)
				if error != OK or config.save(CONFIG_FILE) != OK:
					push_warning("[Mini HUD] Cannot create MCM config; using defaults.")
					owner.apply_config(defaults())
					return
			helper.RegisterConfiguration(MOD_ID, "Mini HUD", CONFIG_DIR,
				"Native Time-slot clock with optional trader timer and verified player kill cells. Toggle or automatic outdoor display; shelters, menus and transitions remain hidden.",
				{"config.ini": owner.apply_config}, owner)
	owner.apply_config(config)
