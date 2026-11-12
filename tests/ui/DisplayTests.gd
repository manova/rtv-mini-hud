extends Node
const Settings = preload("res://rtv-mini-hud/Settings.gd")
const HudPanel = preload("res://rtv-mini-hud/Panel.gd")
const Model = preload("res://rtv-mini-hud/Model.gd")
var checks: Array = []
func _ready() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"name": label, "passed": ok})
	if not ok: push_error(label)
func settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
func data() -> Array:
	return [{"value": "12:34", "icon": "sun", "status": "running"}, {"value": "09:42", "icon": "user", "status": "running"}, {"value": "17", "icon": "skull", "status": "running"}]
func options(timer: bool, kills: bool) -> Dictionary:
	var config = Settings.defaults()
	for key in ["show_trader_timer", "show_kill_counter"]:
		var entry = config.get_value("Bool", key)
		entry.value = timer if key == "show_trader_timer" else kills
		config.set_value("Bool", key, entry)
	return Settings.normalized(config).layout
func _run() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var fresh = Settings.normalized(Settings.defaults())
	check(fresh.layout.show_trader_timer and fresh.layout.show_kill_counter, "fresh defaults retain both optional cells")
	check(fresh.event.physical_keycode == KEY_F8 and fresh.display_mode == Model.MODE_TOGGLE and not fresh.show_without_watch and not fresh.attribution_trace, "existing defaults unchanged")
	var legacy = ConfigFile.new()
	legacy.set_value("Keycode", Settings.ACTION, {"value": KEY_F9, "type": "Key", "altPressed": true})
	legacy.set_value("Dropdown", "display_mode", {"value": Model.MODE_ALWAYS_ON})
	legacy.set_value("Int", "scale", {"value": 135})
	legacy.set_value("Int", "x", {"value": 18})
	legacy.set_value("Bool", "show_without_watch", {"value": true})
	legacy.set_value("Bool", "cumulative_kills", {"value": true})
	legacy.set_value("Custom", "untouched", "sentinel")
	check(Settings.merge_missing(legacy), "upgrade adds new entries")
	var migrated = Settings.normalized(legacy)
	check(migrated.layout.show_trader_timer and migrated.layout.show_kill_counter, "upgrade defaults on")
	check(migrated.event.physical_keycode == KEY_F9 and migrated.event.alt_pressed and migrated.display_mode == Model.MODE_ALWAYS_ON and migrated.layout.scale == 1.35 and migrated.layout.x == 18 and migrated.show_without_watch and migrated.cumulative_kills, "migration preserves saved preferences")
	check(legacy.get_value("Custom", "untouched") == "sentinel" and not Settings.merge_missing(legacy), "migration is idempotent and keeps unknown entries")
	for key in ["show_trader_timer", "show_kill_counter"]:
		var config = Settings.defaults()
		config.set_value("Bool", key, {"value": false})
		Settings.merge_missing(config)
		check(not Settings.normalized(config).layout[key], key + " saved false survives metadata hydration")
		check(config.save(OS.get_environment("MINIHUD_UI_OUTPUT") + "/roundtrip.ini") == OK, key + " save")
		var loaded = ConfigFile.new()
		check(loaded.load(OS.get_environment("MINIHUD_UI_OUTPUT") + "/roundtrip.ini") == OK and not Settings.normalized(loaded).layout[key], key + " saved false survives reload")
		for malformed in [null, false, 0, "false", {}, {"value": 0}, {"value": "false"}]:
			config.set_value("Bool", key, malformed)
			check(Settings.normalized(config).layout[key], key + " invalid entry defaults on: " + str(malformed))
	var panel = HudPanel.new()
	panel.configure(options(false, false))
	get_tree().root.add_child(panel)
	await settle()
	panel.present(data())
	await settle()
	check(panel._cells[0].visible and not panel._cells[1].visible and not panel._cells[2].visible, "configure before ready clock-only")
	for repeat in range(3):
		for combo in [[true,true], [false,true], [true,false], [false,false], [true,true]]:
			var opt = options(combo[0], combo[1])
			panel.configure(opt)
			panel.present(data())
			await settle()
			var label = str(repeat) + " combo " + str(combo)
			check(panel._cells[0].visible and panel._cells[1].visible == combo[0] and panel._cells[2].visible == combo[1], label + " visibility")
			check(is_equal_approx(panel.panel.size.x, HudPanel.CELL_WIDTH * (1 + int(combo[0]) + int(combo[1])) + 16), label + " compact width")
			check(panel.values[0].text == "12:34" and panel.values[1].text == "09:42" and panel.values[2].text == "17", label + " stable readings")
			panel.clear()
			check(not panel.visible, label + " clear hides canvas")
			panel.present(data())
			check(panel.visible, label + " present restores canvas")
	var large = data()
	large[1].value = "VERY LONG TRADER VALUE\nSECOND TRADER\nTHIRD TRADER"
	panel.configure(options(true, true))
	panel.present(large)
	await settle()
	check(panel.panel.size.x > 262 and panel.panel.size.y > 82, "visible multi-trader cell can expand")
	panel.configure(options(false, false))
	await settle()
	check(is_equal_approx(panel.panel.size.x, 98) and is_equal_approx(panel.panel.size.y, 82), "hide oversized trader releases width and height")
	for size in [Vector2i(1280,720), Vector2i(800,600), Vector2i(320,180)]:
		get_tree().root.size = size
		for combo in [[true,true], [false,true], [true,false], [false,false]]:
			for scale in [0.65, 1.0, 1.8]:
				for pos in [Vector2(92,3), Vector2(0,0), Vector2(100,100)]:
					var opt = options(combo[0], combo[1])
					opt.scale = scale; opt.x = pos.x; opt.y = pos.y
					panel.configure(opt); panel.present(data())
					await settle()
					var bounds = Rect2(panel.panel.position, panel.panel.size * panel.panel.scale)
					check(bounds.position.x >= -0.01 and bounds.position.y >= -0.01 and bounds.end.x <= size.x + 0.01 and bounds.end.y <= size.y + 0.01, "bounds " + str([size,combo,scale,pos]))
					if pos == Vector2(92,3): check(bounds.end.x <= size.x - HudPanel.PERMADEATH_SIZE - HudPanel.NATIVE_GAP + 0.01, "default reserved permadeath region")
	var orange = options(false,true); orange.orange = true
	panel.configure(orange); panel.present(data()); await settle()
	check(panel.icons[0].modulate == Color.WHITE and panel.icons[2].modulate == Color.WHITE and panel.icons[1].modulate == HudPanel.ORANGE, "hidden trader tint never leaks onto kill or clock")
	for child in panel.find_children("*", "Control", true, false):
		check(child.mouse_filter == Control.MOUSE_FILTER_IGNORE and child.focus_mode == Control.FOCUS_NONE, "mouse/focus passthrough " + child.get_class())
	var context = {"ready":true,"paused":false}
	for flag in Model.BLOCKING_FLAGS: context[flag] = false
	var model = Model.new()
	check(not model.visible_in(context) and model.toggle(context) and model.visible_in(context), "Toggle starts hidden and toggles")
	model.set_display_mode(Model.MODE_ALWAYS_ON)
	check(model.visible_in(context) and not model.toggle(context), "Always on ignores shortcut")
	for flag in Model.BLOCKING_FLAGS:
		context[flag] = true; check(not model.visible_in(context), "blocked context " + flag); context[flag] = false
	model.set_display_mode(Model.MODE_TOGGLE)
	check(not model.visible_in(context), "return to Toggle clears stale visibility")
	panel.free()
	var passed = checks.all(func(c): return c.passed)
	var result = {"passed":passed,"assertions":checks.size(),"checks":checks}
	FileAccess.open(OS.get_environment("MINIHUD_UI_OUTPUT") + "/ui-results.json", FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
	print("UI_TESTS " + JSON.stringify({"passed":passed,"assertions":checks.size()}))
	get_tree().quit(0 if passed else 1)
