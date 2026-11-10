extends RefCounted
# Synthetic structural negatives plus real-callback fail-closed lifecycle tests.
# These fixtures never replace source in a shipped archive or normal installation.
func run(t, root: Node, lib: Node, hooks: Node, feed: Node) -> void:
	var C = load("res://rtv-mini-hud/CallbackContracts.gd")
	var hooks_script: Script = hooks.get_script()
	var hooks_path := hooks_script.resource_path
	for declaration in ["", "const OBSERVER_CONTRACT := 0\n", "const OBSERVER_CONTRACT := 2\n", "const OBSERVER_CONTRACT := 1.0\n", "const OBSERVER_CONTRACT := true\n", "const OBSERVER_CONTRACT := \"1\"\n", "const OBSERVER_CONTRACT := 1\n"]:
		var script := GDScript.new()
		script.source_code = "extends Node\n" + declaration + "signal kill_event(ev: Dictionary)\nvar _lib\nfunc _on_ai_death(_d, _f): pass\nfunc _on_ai_weapon_damage(_h, _d, _v, _id): pass\nfunc _on_ai_explosion(_d, _id): pass\n"
		t.ok(script.reload() == OK, "marker fixture compiles: " + declaration.strip_edges())
		script.take_over_path(hooks_path)
		var test_root := Node.new()
		var ui := Node.new(); ui.name = "VTKUI"; test_root.add_child(ui)
		var owner: Node = script.new(); owner.name = "VTKHooks"; ui.add_child(owner); owner._lib = lib
		var saved: Dictionary = lib._hooks
		var rows := {}
		for pair in [["ai-death-pre", "_on_ai_death"], ["ai-weapondamage-pre", "_on_ai_weapon_damage"], ["ai-explosiondamage-pre", "_on_ai_explosion"]]:
			rows[pair[0]] = [{"callback":Callable(owner, pair[1]),"priority":100,"id":1}]
		lib._hooks = rows
		var row: Dictionary = rows["ai-death-pre"][0]
		var exact: bool = declaration == "const OBSERVER_CONTRACT := 1\n"
		t.ok(not C.identify(row, "ai-death-pre", test_root, lib).is_empty() == exact, "only exact integer marker 1 accepted: " + declaration.strip_edges())
		if exact:
			for channel in ["ai-weapondamage-pre", "ai-explosiondamage-pre", "ai-death-pre"]:
				var keep: Array = rows[channel]
				rows[channel] = []
				t.ok(C.identify(row, "ai-death-pre", test_root, lib).is_empty(), "missing contract row rejected " + channel)
				rows[channel] = [keep[0], keep[0]]
				t.ok(C.identify(row, "ai-death-pre", test_root, lib).is_empty(), "duplicate contract row rejected " + channel)
				rows[channel] = keep
				var priority = keep[0].priority; keep[0].priority = 101
				t.ok(C.identify(row, "ai-death-pre", test_root, lib).is_empty(), "wrong contract priority rejected " + channel)
				keep[0].priority = priority
				var cb: Callable = keep[0].callback; keep[0].callback = cb.bind(0).unbind(1)
				t.ok(C.identify(row, "ai-death-pre", test_root, lib).is_empty(), "adapted contract method rejected " + channel)
				keep[0].callback = cb
			for channel in ["ai-weapondamage", "ai-explosiondamage", "ai-death"]:
				rows[channel] = [row]
				t.ok(C.identify(row, "ai-death-pre", test_root, lib).is_empty(), "replace contract row rejected " + channel)
				rows.erase(channel)
		lib._hooks = saved
		test_root.free()
		hooks_script.take_over_path(hooks_path)
	# Live loaded Script paths are identity, even without source hashing.
	t.fresh()
	hooks_script.take_over_path("res://fixture-wrong-hooks.gd")
	t.damage(t.target(), t.player); t.reject("wrong loaded Hooks Script path rejected")
	hooks_script.take_over_path(hooks_path)
	t.fresh()
	var hooks_name := hooks.name; hooks.name = "WrongHooks"
	t.damage(t.target(), t.player); t.reject("wrong Hooks node path rejected")
	hooks.name = hooks_name
	if feed:
		t.fresh()
		var feed_script: Script = feed.get_script()
		var feed_path := feed_script.resource_path
		feed_script.take_over_path("res://fixture-wrong-feed.gd")
		t.damage(t.target(), t.player); t.reject("wrong loaded feed Script path rejected")
		feed_script.take_over_path(feed_path)
	# Neither UI styling/source nor VTK totals are attribution authority.
	t.fresh()
	var ui_script: Script = root.get_node("VTKUI").get_script()
	var ui_source := ui_script.source_code
	ui_script.source_code += "\n# unrelated UI source-only fixture\n"
	var previous_count: int = hooks._kill_count
	hooks._kill_count = 9000
	t.damage(t.target(), t.player)
	t.ok(t.observer.read().value == "1", "UI source and VTK total cannot replace native final-blow count")
	ui_script.source_code = ui_source; hooks._kill_count = previous_count
	if feed:
		t.fresh()
		var name_before := feed.name; feed.name = "WrongFeed"
		t.damage(t.target(), t.player); t.reject("wrong feed path fails closed")
		feed.name = name_before
		t.damage(t.target(), t.player)
		t.ok(t.observer.read().value == "N/A" and not t.observer._session_complete and not t.observer._visit_complete, "restoring valid feed never resurrects incomplete total")
		t.fresh()
		var before = feed._hooks; feed._hooks = null
		var row := {"callback":Callable(hooks, "_on_ai_death"),"priority":100}
		t.ok(C.identify(row, "ai-death-pre", root, lib).is_empty(), "feed back-reference mismatch rejected")
		feed._hooks = before
	# Structural checks are repeated, not cached as a permanent grant.
	t.fresh()
	var actual_rows: Array = lib._hooks["ai-weapondamage-pre"]
	var vtk_row: Dictionary = {}
	for row in actual_rows:
		if row.callback == Callable(hooks, "_on_ai_weapon_damage"): vtk_row = row
	var before: int = vtk_row.priority; vtk_row.priority = 101
	t.damage(t.target(), t.player); t.reject("changed live VTK damage callback priority fails closed")
	vtk_row.priority = before
	t.damage(t.target(), t.player)
	t.ok(t.observer.read().value == "N/A" and not t.observer._session_complete and not t.observer._visit_complete, "restored VTK registration never resurrects incomplete total")
