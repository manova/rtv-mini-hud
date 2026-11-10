extends "res://GeneralizedTests.gd"
var toolkit: Node
var lava: Node
var feed: Node
var contract_v1 := false
var feed_active := true

func reject(label: String):
	print("NEGATIVE_DIAG ", JSON.stringify({"test":label,"value":observer.read().value,"count":observer.count,"reason":observer.reason}))
	ok(observer.read().value == "N/A" and observer.count == 0, label)

func run(root: Node, lib: Node, hud: Node, _native_ai: Script = null) -> void:
	host = root; api = lib
	var tree = host.get_tree()
	var previous_scene = tree.current_scene
	hud.set_process(false); hud._kills.uninstall()
	toolkit = tree.root.get_node_or_null("VTKUI/VTKHooks")
	lava = tree.root.get_node_or_null("MurdieLavaLamps")
	feed = tree.root.get_node_or_null("VTKKC_Canvas/VTKFeed")
	map = Node3D.new(); map.name = "CallbackFixtureMap"
	var core = Node.new(); core.name = "Core"
	var camera = Node3D.new(); camera.name = "Camera"
	player = Node3D.new(); player.name = "ID"; npc = Node3D.new()
	map.add_child(core); core.add_child(camera); camera.add_child(player); map.add_child(npc)
	tree.root.add_child(map); tree.current_scene = map; player.add_to_group("Player")
	contract_v1 = toolkit != null and toolkit.get_script().get_script_constant_map().get("OBSERVER_CONTRACT") == 1
	var config = JSON.parse_string(FileAccess.get_file_as_string("user://case.json"))
	feed_active = config.feed_state == "active"
	if toolkit and contract_v1:
		var features = tree.root.get_node("VTKUI")._features
		if config.feed_state == "absent":
			ok(feed == null and toolkit.get_signal_connection_list("kill_event").is_empty(), "HUD never enabled has no feed and no connections")
		else:
			features.set_hud(true, true, true)
			feed = tree.root.get_node_or_null("VTKKC_Canvas/VTKFeed")
			ok(feed != null, "contract feed has explicit live identity")
			features.set_hud(feed_active, feed_active, feed_active)
			ok(toolkit.get_signal_connection_list("kill_event").size() == 1, "active or inactive created feed remains connected")
	if feed:
		if not contract_v1: feed._enabled = true
		feed._was_shelter = false; feed.clear(); feed.set_process(false)
	fresh()
	var absent_aial := not Engine.has_meta("AIActuallyLoots")
	# Prevent old get_meta(null) diagnostic noise; this sentinel is not a trusted owner.
	if absent_aial: Engine.set_meta("AIActuallyLoots", host)
	var old = load("res://BaselineObserver.gd").new()
	observer.uninstall(); old.sync_state(Data.new()); old.install(host, api, AI)
	if api.version()=="3.4.2":
		ok(old.read().value == "0", "released observer starts numeric with actual companion callbacks")
	else:
		ok(old.read().value == "N/A" and old.reason == "Unverified Metro API.", "released observer rejects newer loader before combat")
	damage(target(), player)
	ok(old.read().value == "N/A" and old.count == 0, "released 0.4.5 remains unavailable after first death with actual companion callbacks")
	old.uninstall(); old = null
	if absent_aial: Engine.remove_meta("AIActuallyLoots")
	fresh()
	var start_count: int = toolkit._kill_count if toolkit else 0
	var start_rows: int = feed._rows.size() if feed else 0
	var victim = target()
	damage(victim, player)
	ok(observer.read().value == "1", "candidate counts actual companion-callback player death")
	if toolkit:
		ok(toolkit._kill_count == start_count + 1 and toolkit._seen_deaths.has(victim.get_instance_id()), "actual Toolkit bookkeeping executed")
		ok(not toolkit._last_damager.has(victim.get_instance_id()), "actual Toolkit attacker bookkeeping consumed")
	if feed: ok(feed._rows.size() == (mini(start_rows + 1, 5) if feed_active else 0), "actual Toolkit feed obeys active/inactive state")
	damage(victim, player); victim.ExplosionDamage(Vector3.UP, player)
	ok(observer.read().value == "1", "actual companion callback corpse repetitions do not add credit")
	fresh()
	damage(target(), npc)
	ok(observer.read().value == "0", "actual companions NPC-first remains numeric zero")
	var assist = target(); damage(assist, player, 10.0); damage(assist, npc, 90.0)
	ok(observer.read().value == "0", "actual companions do not import Toolkit assist attribution")
	target().ExplosionDamage(Vector3.UP, player); target().ExplosionDamage(Vector3.UP, npc)
	ok(observer.read().value == "1", "actual companions player explosion only")
	if lava:
		fresh()
		var boss = target(4); boss.variant.name = "Bogeyman"
		damage(boss, player)
		ok(observer.read().value == "1", "boss death remains counted with substantive Lava callback")
		ok("bogeyman" in lava._bosses_killed(), "actual Lava boss-unlock bookkeeping executed")
		ok(FileAccess.file_exists("user://MurdieLavaLamps_Bosses.tres"), "actual Lava boss file saved only in isolated profile")
		var base: Script = lava.get_script().get_script_constant_map().LavaLamp
		while base.get_base_script() != null: base = base.get_base_script()
		var source = base.source_code
		fresh(); base.source_code = source + "\n# altered inherited dependency fixture\n"
		damage(target(), player); reject("changed inherited Lava source is rejected")
		base.source_code = source
	# Exact callback identity, registration multiplicity, priority, and Metro link.
	for channel in ["ai-death-pre", "ai-death-post"]:
		var actual_rows: Array = api._hooks.get(channel, []).duplicate()
		for row in actual_rows:
			var owner = row.callback.get_object()
			if not is_instance_valid(owner) or (owner != toolkit and owner != lava): continue
			var original: Callable = row.callback
			fresh(); ids.append(api.hook(channel, original, 100)); damage(target(), player)
			reject("duplicate companion registration rejected " + channel)
			fresh(); row.priority = 101; damage(target(), player)
			reject("changed companion priority rejected " + channel); row.priority = 100
			fresh(); row.callback = original.bind(1).unbind(1); damage(target(), player)
			reject("bound companion method rejected " + channel); row.callback = original
			fresh(); var script: Script = owner.get_script(); var source: String = script.source_code
			script.source_code = source + "\n# altered callback source fixture\n"
			damage(target(), player)
			if owner == toolkit and contract_v1:
				ok(observer.read().value == "1", "contract-v1 unrelated source edits do not require a hash refresh")
			else: reject("changed companion source rejected " + channel)
			script.source_code = source
			fresh(); var before_lib = owner._lib; owner._lib = null
			# Do not execute a broken third-party callback; directly evaluate its trust gate.
			ok(Observer.Callbacks.identify(row, channel, tree.root, api).is_empty(), "different companion Metro link rejected " + channel)
			owner._lib = before_lib
	for channel in ["ai-death-pre", "ai-death-post", "ai-death-callback"]:
		fresh(); ids.append(api.hook(channel, func(_d, _f): pass, 0))
		damage(target(), player); reject("unknown callback cannot borrow companion budget " + channel)
		await tree.process_frame
	fresh()
	ids.append(api.hook("unrelated-fixture-pre", func(): pass, 0))
	var gap = target(); gap.death_helper = func(): api._dispatch("unrelated-fixture-pre", [])
	damage(gap, player); reject("native-body dispatch cannot borrow pre or post budget")
	if toolkit:
		fresh()
		var extra := func(_ev): pass
		toolkit.connect("kill_event", extra)
		damage(target(), player); reject("extra Toolkit signal recipient rejected")
		toolkit.disconnect("kill_event", extra)
		fresh()
		toolkit.connect("kill_event", extra, Object.CONNECT_DEFERRED)
		damage(target(), player); reject("deferred Toolkit signal recipient rejected")
		toolkit.disconnect("kill_event", extra); await tree.process_frame
		if feed:
			fresh()
			var normal := Callable(feed, "_on_kill_event")
			toolkit.disconnect("kill_event", normal)
			var adapted := normal.bind({}).unbind(1)
			toolkit.connect("kill_event", adapted)
			damage(target(), player); reject("bound Toolkit signal recipient rejected")
			toolkit.disconnect("kill_event", adapted); toolkit.connect("kill_event", normal)
			fresh()
			var source: String = feed.get_script().source_code
			feed.get_script().source_code = source + "\n# changed signal recipient fixture\n"
			damage(target(), player)
			if contract_v1: ok(observer.read().value == "1", "contract-v1 UI source edit stays compatible")
			else: reject("changed Toolkit signal source rejected")
			feed.get_script().source_code = source
		fresh()
		var dependency: Script = toolkit.get_script().get_script_constant_map().KC
		var source: String = dependency.source_code
		dependency.source_code = source + "\n# changed Toolkit dependency fixture\n"
		damage(target(), player)
		if contract_v1: ok(observer.read().value == "1", "contract-v1 does not pin unrelated dependency source")
		else: reject("changed actual Toolkit dependency rejected")
		dependency.source_code = source
		fresh()
		# A source-verified pre callback cannot mask a transient native-body dispatch.
		var before: Array = api._hooks["ai-death-pre"].duplicate()
		var broken = target()
		broken.death_helper = func(): api._hooks["ai-death-pre"].reverse()
		damage(broken, player); reject("pre registry mutation inside native body rejected")
		api._hooks["ai-death-pre"] = before
	if contract_v1: await load("res://VTKContractTests.gd").new().run(self, tree.root, api, toolkit, feed)
	fresh()
	var start := Time.get_ticks_usec()
	for i in 30: damage(target(), player)
	var elapsed := Time.get_ticks_usec() - start
	ok(observer.read().value == "30", "thirty real companion callback events stay counted")
	print("CALLBACK_TIMING ", JSON.stringify({"events":30,"microseconds":elapsed,"toolkit":toolkit!=null,"lava":lava!=null,"developer":api._developer_mode,"gameplay":false}))
	fresh(); observer.uninstall(); observer = null
	tree.current_scene = previous_scene; map.free()
	hud._kills = Observer.new(); hud._kills.sync_state(hud._game_data); hud._kills.install(hud, api)
	ok(hud._kills.read().value == "0", "production observer restored after compatibility fixtures")
