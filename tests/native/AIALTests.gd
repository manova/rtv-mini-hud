extends RefCounted
const Observer = preload("res://rtv-mini-hud/KillObserver.gd")
const AI = preload("res://FakeAI.gd")
class Data extends Resource:
	var menu := false
	var isDead := false
class Impostor extends Node:
	var calls := 0
	func _on_death(_direction, _force): calls += 1
var host: Node
var api: Node
var aial: Node
var map: Node3D
var player: Node3D
var npc: Node3D
var observer: RefCounted
var data: Resource
var ids: Array[int] = []
var trusted_row: Dictionary
var trusted_callable: Callable

func ok(value: bool, label: String):
	host.check(value, "AIAL: " + label)
func fresh():
	if observer: observer.uninstall()
	for id in ids: api.unhook(id)
	ids.clear()
	trusted_row.callback = trusted_callable
	aial._lib = api
	Engine.set_meta("AIActuallyLoots", aial)
	aial._corpses.clear()
	data = Data.new()
	observer = Observer.new()
	observer.sync_state(data)
	observer.install(host, api, AI)
	ok(observer.read().value == "0", "fresh numeric observer")
func target(faction: int = 1):
	var v = AI.new()
	v.variant.faction = faction
	v.container = Node3D.new()
	v.add_child(v.container)
	map.add_child(v)
	return v
func damage(v, actor, amount: float = 100.0):
	v.WeaponDamage("Torso", amount, Vector3.FORWARD, actor)
func rejected(label: String):
	ok(observer.read().value == "N/A" and observer.count == 0, label)

func run(root: Node, lib: Node, hud: Node):
	host = root
	api = lib
	aial = Engine.get_meta("AIActuallyLoots")
	var saved_corpses: Array = aial._corpses.duplicate()
	var aial_physics = aial.is_physics_processing()
	aial.set_physics_process(false)
	hud.set_process(false)
	hud._kills.uninstall()
	for row in api._hooks["ai-death-post"]:
		if row.callback == Callable(aial, "_on_death"):
			trusted_row = row
			trusted_callable = row.callback
	ok(not trusted_row.is_empty(), "actual AIAL Death callback registered")
	ok(aial.get_script().source_code.replace("\r\n", "\n").sha256_text() == Observer.AIAL_SOURCE_SHA,
		"actual unchanged AIAL source digest")
	var tree = host.get_tree()
	var previous_scene = tree.current_scene
	map = Node3D.new()
	map.name = "AIALFixtureMap"
	var core = Node.new()
	core.name = "Core"
	var camera = Node3D.new()
	camera.name = "Camera"
	player = Node3D.new()
	player.name = "ID"
	npc = Node3D.new()
	map.add_child(core)
	core.add_child(camera)
	camera.add_child(player)
	map.add_child(npc)
	tree.root.add_child(map)
	tree.current_scene = map
	player.add_to_group("Player")
	fresh()
	var victim = target()
	ok(aial._affects(victim), "fixture eligibility explicitly verified, not presumed type rejection")
	var source = Node3D.new()
	map.add_child(source)
	source.set_meta("aal_reserved", [victim.get_instance_id(), 0.0])
	victim.set_meta("aal_loot", {"target": source, "left": 1, "t": 0.0})
	victim.set_meta("aal_home", source)
	victim.set_meta("aal_homerun", true)
	victim.looting = true
	damage(victim, player, 20.0)
	ok(observer.read().value == "0" and victim.health == 80.0, "real AIAL damage pre remains nonlethal")
	ok(victim.get_meta("aal_attacker", null) == player, "real AIAL attacker metadata executed")
	damage(victim, player, 80.0)
	ok(observer.read().value == "1" and observer.count == 1, "player final blow with substantive AIAL handler")
	ok(not victim.has_meta("aal_loot") and not victim.has_meta("aal_home")
		and not victim.has_meta("aal_homerun") and not victim.has_meta("aal_visited")
		and not victim.has_meta("aal_attacker") and not victim.looting,
		"real AIAL task and attacker metadata cleanup executed")
	ok(not source.has_meta("aal_reserved"), "real AIAL container reservation released")
	ok(aial._corpses.size() == 1 and aial._corpses[0].c == victim.container,
		"real AIAL corpse registration executed")
	damage(victim, player)
	damage(victim, player)
	victim.ExplosionDamage(Vector3.UP, player)
	ok(observer.read().value == "1" and observer.count == 1, "repeated corpse bullets/explosion excluded")
	var boss = target(4)
	ok(not aial._affects(boss), "AIAL Boss no-op branch explicitly verified")
	damage(boss, player)
	ok(observer.read().value == "2", "Boss counts while trusted AIAL callback takes no-op branch")
	fresh()
	damage(target(), npc)
	ok(observer.read().value == "0" and observer._visit_complete and observer._session_complete,
		"NPC-first death from live sequence stays complete numeric zero")
	var assisted = target()
	damage(assisted, player, 20.0)
	damage(assisted, npc, 80.0)
	ok(observer.read().value == "0", "player assist followed by NPC final blow excluded")
	damage(target(), player)
	ok(observer.read().value == "1", "player kill after NPC deaths counted")
	target().ExplosionDamage(Vector3.UP, player)
	target().ExplosionDamage(Vector3.UP, npc)
	ok(observer.read().value == "2", "player explosion counted and NPC explosion excluded")

	# A real actor.owner link makes AIAL's killer/body bookkeeping execute.
	fresh()
	var killer = target()
	var actor = Node3D.new()
	killer.add_child(actor)
	actor.owner = killer
	var killed = target()
	damage(killed, actor)
	ok(killer.get_meta("aal_kill", null) == killed.container,
		"real NPC killer receives the corpse bookkeeping marker")
	ok(observer.read().value == "0", "NPC corpse ownership grants no player credit")

	# Exact identity: no extra or merely similar callback can borrow the budget.
	for channel in ["ai-death-pre", "ai-death-post", "ai-death-callback"]:
		fresh()
		ids.append(api.hook(channel, func(_d, _f): pass, 0))
		damage(target(), player)
		rejected("unknown callback rejected " + channel)
	fresh()
	ids.append(api.hook("ai-death-post", trusted_callable, 100))
	damage(target(), player)
	rejected("duplicate trusted registration rejected")
	fresh()
	trusted_row.callback = trusted_callable.bind(1).unbind(1)
	damage(target(), player)
	rejected("bind/unbind adapter cannot borrow the trusted method identity")
	fresh()
	var impostor = Impostor.new()
	map.add_child(impostor)
	trusted_row.callback = Callable(impostor, "_on_death")
	Engine.set_meta("AIActuallyLoots", impostor)
	damage(target(), player)
	rejected("same method name on another source/owner rejected")
	ok(impostor.calls == 1, "observer did not suppress the unsupported callback")
	fresh()
	var foreign = api.get_script().new()
	var wrong_lib_target = target()
	foreign._caller = wrong_lib_target
	aial._lib = foreign
	damage(wrong_lib_target, player)
	rejected("trusted handler bound to another Metro instance rejected")
	aial._lib = api
	foreign.free()
	fresh()
	Engine.set_meta("AIActuallyLoots", impostor)
	damage(target(), player)
	rejected("autoload metadata owner mismatch rejected")
	fresh()
	trusted_row.priority = 101
	damage(target(), player)
	rejected("trusted handler priority mutation rejected")
	trusted_row.priority = 100

	# Same source except an added comment, at the same resource path: digest gate.
	fresh()
	var real_script = aial.get_script()
	var changed = GDScript.new()
	changed.source_code = real_script.source_code + "\n# isolated altered-source negative fixture\n"
	ok(changed.reload() == OK, "altered-source fixture compiles without modifying real AIAL")
	changed.take_over_path("res://AIActuallyLoots/Main.gd")
	var changed_owner = changed.new()
	changed_owner._lib = api
	Engine.set_meta("AIActuallyLoots", changed_owner)
	trusted_row.callback = Callable(changed_owner, "_on_death")
	damage(target(), player)
	rejected("different source digest at exact AIAL path rejected")
	trusted_row.callback = trusted_callable
	Engine.set_meta("AIActuallyLoots", aial)
	real_script.take_over_path("res://AIActuallyLoots/Main.gd")
	changed_owner.free()

	# Regression supplied by independent review: replace/restore a callback so
	# endpoint-only snapshots and a widened pre->post budget would both match.
	fresh()
	var swapped = target()
	var replacement = func(_d, _f):
		swapped.death_helper = Callable()
		swapped.dead = false
		swapped.health = 100.0
		damage(swapped, npc)
		trusted_row.callback = trusted_callable
	swapped.death_helper = func(): trusted_row.callback = replacement
	damage(swapped, player)
	rejected("transient registry substitution/restoration cannot hide NPC final blow")
	ok(swapped.dead and swapped.health == 0.0 and swapped.original_calls == 2,
		"impostor counterexample executed nested native damage without observer suppression")
	ok(trusted_row.callback == trusted_callable, "impostor restored registry before late observer")
	fresh()
	var changed_during_body = target()
	changed_during_body.death_helper = func(): trusted_row.priority = 99
	damage(changed_during_body, player)
	rejected("registry change within native Death body rejected")
	trusted_row.priority = 100
	fresh()
	var original_rows: Array = api._hooks["ai-death-post"].duplicate()
	var original_death_refs: int = api._hooked_bases["ai-death"]
	var unhooked = target()
	unhooked.death_helper = func(): api.unhook(trusted_row.id)
	damage(unhooked, player)
	rejected("trusted callback removed within native Death body rejected")
	api._hooks["ai-death-post"] = original_rows
	api._hooked_bases["ai-death"] = original_death_refs
	ok(api._hooks["ai-death-post"] == original_rows
		and api._hooked_bases["ai-death"] == original_death_refs,
		"removed callback fixture restores both registry and Metro base count")
	fresh()
	var reordered_rows: Array = api._hooks["ai-death-post"].duplicate()
	var reordered = target()
	reordered.death_helper = func(): api._hooks["ai-death-post"].reverse()
	damage(reordered, player)
	rejected("post callback order changed within native Death body rejected")
	api._hooks["ai-death-post"] = reordered_rows
	fresh()
	var freed_owner = Impostor.new()
	map.add_child(freed_owner)
	ids.append(api.hook("ai-death-post", Callable(freed_owner, "_on_death"), 99))
	var freed_callback = target()
	freed_callback.death_helper = func(): freed_owner.free()
	damage(freed_callback, player)
	rejected("invalidated callback and dispatch cleanup cannot borrow the allowance")
	fresh()
	var interrupted = target()
	interrupted.death_helper = func(): api._dispatch("loader-loadcharacter-pre", [])
	damage(interrupted, player)
	rejected("character restore within native death cannot receive callback allowance")
	fresh()
	ids.append(api.hook("unrelated-fixture-pre", func(): pass, 0))
	var extra_dispatch = target()
	extra_dispatch.death_helper = func(): api._dispatch("unrelated-fixture-pre", [])
	damage(extra_dispatch, player)
	rejected("native-body foreign dispatch cannot consume AIAL allowance")
	fresh()
	var nested = target()
	nested.helper = func():
		nested.helper = Callable()
		damage(nested, npc)
	damage(nested, player, 0.0)
	rejected("same-wrapper NPC final blow remains rejected with AIAL present")
	fresh()
	var cross = target()
	cross.helper = func():
		cross.helper = Callable()
		cross.ExplosionDamage(Vector3.FORWARD, npc)
	damage(cross, player, 0.0)
	rejected("nested explosion remains rejected with AIAL present")

	# Recorded lifecycle order and incomplete-scope behavior.
	fresh()
	damage(target(), player)
	api._dispatch("loader-loadcharacter-pre", [])
	ok(observer.read().value == "1", "same-scene character restore preserves valid count")
	data.isDead = true
	observer.sync_state(data)
	ok(observer.read().value == "0" and observer.count == 1, "ordinary death resets visit only")
	data.isDead = false
	observer.sync_state(data)
	observer.cumulative = true
	ok(observer.read().value == "1", "cumulative count survives ordinary lifecycle boundary")
	observer.cumulative = false
	observer._ambiguous("fixture unknown prior attribution")
	api._dispatch("loader-loadcharacter-pre", [])
	ok(observer.read().value == "N/A", "character reload cannot heal ambiguous attribution")
	api._dispatch("loader-loadscene-pre", ["Cabin"])
	ok(observer.read().value == "N/A", "load intent alone cannot heal ambiguous attribution")
	var previous_player = player
	camera.remove_child(previous_player)
	previous_player.free()
	player = Node3D.new()
	player.name = "ID"
	camera.add_child(player)
	player.add_to_group("Player")
	ok(observer.read().value == "0", "actual new player identity restores a fresh visit")
	observer.cumulative = true
	ok(observer.read().value == "N/A", "new visit never repairs incomplete session total")
	fresh()
	observer.trace.configure(true)
	var traced = target()
	damage(traced, player)
	ok(observer.read().value == "1", "diagnostic trace preserves valid attribution")
	host.set_meta("aial_callback_coverage", {
		"realHandler": true, "metadataCleanup": true, "corpseRegistration": true,
		"playerNpcCorpse": true, "transientRegistryCounterexample": true,
		"removedReorderedFreedCallbacks": true,
		"developer": api._developer_mode, "gameplay": false,
		"limit": "native-style modeled damage bodies with real unchanged AIAL autoload and callbacks; no AI navigation or looting scene"})
	fresh()
	observer.uninstall()
	observer = null
	aial._corpses = saved_corpses
	tree.current_scene = previous_scene
	map.free()
	aial.set_physics_process(aial_physics)
	hud._kills = Observer.new()
	hud._kills.sync_state(hud._game_data)
	hud._kills.install(hud, lib)
	ok(hud._kills.read().value == "0", "production observer restored after fixture")
	var death_ref_count := 0
	for channel in api._hooks:
		if api._hook_base_of(channel) == "ai-death":
			death_ref_count += api._hooks[channel].size()
	ok(api._hooked_bases["ai-death"] == death_ref_count,
		"restored production Death registry and base refcount agree")
