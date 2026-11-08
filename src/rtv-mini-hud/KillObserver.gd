extends RefCounted
# Observes native final blows. No damage calls, returns, saves or AI state writes.
# Unrelated mods/probes are unrestricted. Combat extensions that change the
# witnessed native semantics are unsupported; this is not an arbitrary-code guard.
const Trace := preload("res://rtv-mini-hud/AttributionTrace.gd")
const Reader := preload("res://rtv-mini-hud/TimerReader.gd")
const Native := preload("res://rtv-mini-hud/NativeAIContract.gd")
const Callbacks := preload("res://rtv-mini-hud/CallbackContracts.gd")
const AI_PATH := "res://Scripts/AI.gd"
const LOADER_SHA := "30c39e3846957f43925e49ef2449c2ca8f6940c77446af169cfafc858975bcc8"
const LATE := 1000000
const EARLY := -1000000
# A narrow, source-verified exception for synchronous corpse bookkeeping.
# No unknown callback receives a sequence allowance.
const AIAL_SOURCE_SHA := "93c45108d1f1d64cc037d739ffbdb25a8b93d89e198329fbf0e703e000d38c85"
const DEATH_CHANNELS := ["ai-death-pre", "ai-death-post", "ai-death-callback"]
const CHANNELS := ["ai-weapondamage", "ai-explosiondamage", "ai-death"]
var trace := Trace.new()
var count := 0
var visit_count := 0
var cumulative := false
var reason := "Waiting for native damage observation."
var _lib: Object
var _script: Script
var _owner: WeakRef
var _data: Object
var _hooks: Array[int] = []
var _spec: Array = []
var _started := false
var _valid := false
var _session_complete := true
var _visit_complete := true
var _pending: Dictionary = {}
var _seen: Dictionary = {}
var _scene_id := 0
var _player_id := 0
var _epoch := 0
var _dead := false
var _menu := false
var _reading := false
var _read_reentry := false
var _fixture_contract := false # Explicitly enabled only by isolated test entry.

func install(owner: Node, lib: Object, fixture_script: Script = null) -> void:
	if _started: return
	_started = true
	_owner = weakref(owner)
	_lib = lib
	if not is_instance_valid(lib) or Reader.property(lib, &"_is_ready") != true:
		reason = "Metro is not ready."
		return
	var loader: Script = lib.get_script()
	if loader == null or not loader.has_source_code() or loader.source_code.replace("\r\n", "\n").sha256_text() != LOADER_SHA:
		reason = "Unverified Metro API."
		return
	_script = fixture_script if fixture_script != null else load(AI_PATH)
	_fixture_contract = fixture_script != null
	if not _fixture_contract and not Native.verified(_script):
		reason = "Native damage/death methods differ from this build."
		return
	# Literal names enroll exact methods in unchanged MML's generated wrappers.
	_add("ai-weapondamage-pre", _weapon_before, LATE)
	_add("ai-weapondamage-post", _weapon_after, EARLY)
	_add("ai-explosiondamage-pre", _explosion_before, LATE)
	_add("ai-explosiondamage-post", _explosion_after, EARLY)
	_add("ai-death-pre", _death_before, EARLY)
	_add("ai-death-pre", _death_native_before, LATE)
	_add("ai-death-post", _death_native_after, EARLY)
	_add("ai-death-post", _death_after, LATE)
	# Scene/new-game/reset intent is distinct from restoring character data into
	# an already-established scene (the native Compiler's normal Spawn order).
	_add("loader-loadscene-pre", _load_scene, EARLY)
	_add("loader-newgame-pre", _new_game, EARLY)
	_add("loader-loadcharacter-pre", _load_character, EARLY)
	_add("loader-resetcharacter-pre", _reset_character, EARLY)
	_valid = not _hooks.has(-1)
	if not _valid:
		reason = "Observer registration failed."
		uninstall()
		return
	reason = ""
	var conflict := _coverage()
	if not conflict.is_empty(): reason = conflict
	print("[Mini HUD] Native final-blow observer installed; unchanged Metro 3.4.2.")

func _add(name: String, callback: Callable, priority: int) -> void:
	var id: int = _lib.hook(name, callback, priority)
	_hooks.append(id)
	_spec.append({"name":name, "callback":callback, "priority":priority, "id":id})

func uninstall() -> void:
	if is_instance_valid(_lib):
		for id in _hooks:
			if id >= 0: _lib.unhook(id)
	_hooks.clear()
	_spec.clear()
	_pending.clear()
	_valid = false

func _coverage() -> String:
	if not is_instance_valid(_lib) or Engine.get_meta("RTVModLib", null) != _lib:
		return "Metro instance changed."
	if not _fixture_contract and (ResourceLoader.get_cached_ref(AI_PATH) != _script or not Native.verified(_script)):
		return "Native damage/death coverage changed."
	var registry = Reader.property(_lib, &"_hooks")
	var bases = Reader.property(_lib, &"_hooked_bases")
	if not registry is Dictionary or not bases is Dictionary or Reader.property(_lib, &"_any_mod_hooked") != true:
		return "Damage dispatch unavailable."
	for base in CHANNELS:
		if not registry.get(base, []).is_empty(): return "Damage/death replacement is unsupported."
		if not bases.has(base): return "Damage dispatch unavailable."
	for own in _spec:
		if not bases.has(_lib._hook_base_of(own.name)):
			return "Required observation dispatch disappeared."
		var rows = registry.get(own.name, [])
		if not rows is Array: return "Observer registry changed."
		var found := 0
		for row in rows:
			if not row is Dictionary or not row.get("callback") is Callable or not row.get("priority") is int:
				return "Observer registry changed."
			if row.get("id") == own.id and row.callback == own.callback and row.priority == own.priority:
				found += 1
			elif own.name.begins_with("ai-") and row.callback.is_valid():
				# Damage pre LAST / post FIRST; Death pre FIRST / post LAST.
				if (own.priority == LATE and row.priority >= LATE) or (own.priority == EARLY and row.priority <= EARLY):
					return "Another hook crosses the damage witness boundary."
		if found != 1: return "Required observer hook disappeared."
	return ""

# Copy the exact dispatch identities; never retain the mutable registry rows.
func _death_snapshot() -> Dictionary:
	var registry = Reader.property(_lib, &"_hooks")
	if not registry is Dictionary: return {}
	var snapshot := {}
	for channel in DEATH_CHANNELS:
		var rows = registry.get(channel, [])
		if not rows is Array: return {}
		var copied := []
		for row in rows:
			if not row is Dictionary or not row.get("callback") is Callable or not row.get("priority") is int or not row.get("id") is int:
				return {}
			copied.append({"callback":row.callback, "priority":row.priority, "id":row.id})
		snapshot[channel] = copied
	return snapshot

func _trusted_aial_death(row: Dictionary) -> bool:
	var cb: Callable = row.callback
	if not cb.is_valid() or row.priority != 100: return false
	var owner = cb.get_object()
	if not is_instance_valid(owner) or not Engine.has_meta("AIActuallyLoots") or owner != Engine.get_meta("AIActuallyLoots"): return false
	# Equality with a standard method callable excludes bind/unbind/lambda adapters.
	if cb != Callable(owner, "_on_death"): return false
	var script: Script = owner.get_script()
	if script == null or script.resource_path != "res://AIActuallyLoots/Main.gd" or not script.has_source_code():
		return false
	if script.source_code.replace("\r\n", "\n").sha256_text() != AIAL_SOURCE_SHA: return false
	# The pinned source declares a plain field; no foreign getter is invoked.
	return owner.get("_lib") == _lib

func _death_allowance(channel: String) -> int:
	var snapshot: Dictionary = _pending.death_hooks
	if not snapshot["ai-death-callback"].is_empty(): return -1
	var allowed := {}
	var owner = _owner.get_ref() if _owner else null
	var root = owner.get_tree().root if is_instance_valid(owner) and owner.is_inside_tree() else null
	for row in snapshot[channel]:
		if row.callback in [_death_before, _death_native_before, _death_native_after, _death_after]: continue
		var identity := ""
		if channel == "ai-death-post" and _trusted_aial_death(row):
			identity = "AIActuallyLoots._on_death@1.2.0"
		else:
			identity = Callbacks.identify(row, channel, root, _lib)
		if identity.is_empty() or allowed.has(identity): return -1
		allowed[identity] = true
	return allowed.size()

func _toolkit_snapshot() -> Variant:
	var owner = _owner.get_ref() if _owner else null
	if not is_instance_valid(owner) or not owner.is_inside_tree(): return null
	var root = owner.get_tree().root
	for row in _pending.death_hooks["ai-death-pre"]:
		if row.callback in [_death_before, _death_native_before]: continue
		if Callbacks.identify(row, "ai-death-pre", root, _lib).is_empty(): return null
		return Callbacks.toolkit_connections(row.callback.get_object(), root)
	return []

func _ambiguous(message: String) -> void:
	_session_complete = false
	_visit_complete = false
	reason = message
	if trace.active(): trace.record("ambiguous", {"reason":message, "session":count, "visit":visit_count})
	if not _pending.is_empty(): _pending.bad = true

func _reset_visit(message: String, real_boundary: bool = false) -> void:
	var interrupted := not _pending.is_empty()
	if interrupted: _ambiguous("Lifecycle changed during damage.")
	_pending.clear()
	visit_count = 0
	_visit_complete = real_boundary or (_visit_complete and not interrupted)
	_epoch += 1
	if trace.active(): trace.record("scope", {"reason":message, "epoch":_epoch})

func _load_scene(_scene) -> void: _load_started()
func _new_game(_difficulty, _season) -> void: _load_started()
func _load_character() -> void:
	# Native LoadCharacter restores player inventory/vitals, not the AI visit.
	# Never clear a prior coverage failure or change counts/completeness here.
	if not _pending.is_empty():
		_ambiguous("Character restoration interrupted damage.")
		_pending.clear()
	if trace.active(): trace.record("character_restore", {"epoch":_epoch, "session":count, "visit":visit_count, "session_complete":_session_complete, "visit_complete":_visit_complete})
func _reset_character() -> void: _load_started()
func _load_started() -> void:
	_visit_complete = false
	if not _pending.is_empty():
		_ambiguous("Lifecycle changed during damage.")
		_pending.clear()
	if trace.active(): trace.record("load_intent", {"epoch":_epoch, "session":count, "visit":visit_count, "session_complete":_session_complete, "visit_complete":_visit_complete})
	# A load attempt is not evidence of a completed new visit. Scene/player
	# identity must actually change before visit totals become complete again.

func sync_state(data: Object) -> void:
	_data = data
	_scene()

func _scene() -> Node:
	var owner = _owner.get_ref() if _owner else null
	if not is_instance_valid(owner) or not owner.is_inside_tree(): return null
	var scene: Node = owner.get_tree().current_scene
	var sid := scene.get_instance_id() if is_instance_valid(scene) else 0
	var player = scene.get_node_or_null("Core/Camera/ID") if is_instance_valid(scene) else null
	var pid := player.get_instance_id() if is_instance_valid(player) else 0
	if sid != _scene_id or pid != _player_id:
		_scene_id = sid
		_player_id = pid
		_reset_visit("scene_or_player_changed", true)
		_seen.clear()
	var dead = Reader.property(_data, &"isDead")
	var menu = Reader.property(_data, &"menu")
	if not dead is bool or not menu is bool:
		_ambiguous("Player lifecycle state is unavailable.")
		return null
	if (dead and not _dead) or (menu and not _menu): _reset_visit("death_or_menu")
	_dead = dead
	_menu = menu
	return scene

func read() -> Dictionary:
	_scene()
	var coverage := _coverage() if _valid else reason
	if not coverage.is_empty():
		reason = coverage
		# Missing coverage could hide intervening events; do not resurrect a total.
		_session_complete = false
		_visit_complete = false
	var complete := _session_complete if cumulative else _visit_complete
	if not _valid or not complete or not coverage.is_empty():
		return {"status":"unavailable", "value":"N/A", "icon":"skull"}
	return {"status":"running", "value":str(count if cumulative else visit_count), "icon":"skull"}

static func _finite(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _vector(value) -> bool:
	return value is Vector3 and is_finite(value.x) and is_finite(value.y) and is_finite(value.z)

func _weapon_before(hitbox, damage, vector, actor) -> void:
	_begin("weapon", actor, [hitbox, damage, vector], hitbox is String and _finite(damage) and _vector(vector))
func _weapon_after(hitbox, damage, vector, actor) -> void: _finish("weapon", actor, [hitbox, damage, vector])
func _explosion_before(direction, actor) -> void: _begin("explosion", actor, [direction], _vector(direction))
func _explosion_after(direction, actor) -> void: _finish("explosion", actor, [direction])

func _begin(kind: String, actor, args: Array, typed: bool) -> void:
	if not _valid: return
	if _reading:
		_read_reentry = true
		_ambiguous("Reentrant observation is unsupported."); return
	if not _pending.is_empty():
		_ambiguous("Overlapping damage events.")
		return
	var coverage := _coverage()
	if not coverage.is_empty(): _ambiguous(coverage); return
	var scene := _scene()
	var target = Reader.property(_lib, &"_caller")
	if scene == null or not target is Node or not is_instance_valid(target) or target.get_script() != _script or not scene.is_ancestor_of(target):
		_ambiguous("Damage target or lifecycle is unsupported."); return
	var base := "ai-weapondamage" if kind == "weapon" else "ai-explosiondamage"
	if not _lib._wrapper_active.has(str(target.get_instance_id()) + ":" + base):
		_ambiguous("Damage callback has no active wrapper."); return
	# Never stringify callback args or arbitrary Objects. Validate before trace.
	if not typed or not (actor == null or (actor is Node3D and is_instance_valid(actor))):
		_ambiguous("Unsupported damage argument types."); return
	_reading = true
	_read_reentry = false
	var health = target.get(&"health")
	var dead = target.get(&"dead")
	var variant = target.get(&"variant")
	var sensor = target.get(&"sensor")
	var faction = Native.plain_value(variant, &"faction")
	var sensor_type = Native.plain_value(sensor, &"type")
	var enums_ok := Native.enum_matches(variant, "Faction", {"Nomad":0,"Bandit":1,"Guard":2,"Military":3,"Boss":4}) and Native.enum_matches(sensor, "Type", {"Enemy":0,"Nomad":1})
	_reading = false
	if _read_reentry:
		_ambiguous("State observation reentered damage."); return
	if not enums_ok or not _finite(health) or not dead is bool or not faction is int or faction < 0 or faction > 4 or not sensor_type is int or sensor_type < 0 or sensor_type > 1:
		_ambiguous("AI damage state is unsupported."); return
	if not dead and _seen.has(target.get_instance_id()):
		_ambiguous("Previously dead AI was revived in the same visit."); return
	var player := scene.get_node_or_null("Core/Camera/ID")
	if not dead and kind == "weapon" and float(health) <= 0.0:
		_ambiguous("Live AI health was already nonpositive."); return
	var expected: float = float(health) - float(args[1]) if kind == "weapon" and not dead else float(health)
	var death_hooks := _death_snapshot()
	if death_hooks.is_empty():
		_ambiguous("Death callback registry is unavailable."); return
	_pending = {"target":weakref(target), "identity":target.get_instance_id(), "kind":kind,
		"actor":weakref(actor) if is_instance_valid(actor) else null, "actor_id":Trace.identity(actor),
		"args":args.duplicate(), "expected":expected, "alive":not dead,
		"player":actor == player and is_instance_valid(player) and player.is_in_group("Player"),
		"enemy":sensor_type == 0 and faction >= 1 and faction <= 4,
		"epoch":_epoch, "seq":_lib.seq(), "deaths":0, "death_done":false, "bad":false,
		"dev":_lib._developer_mode, "dispatch":_dispatch_counts(),
		"death_hooks":death_hooks, "death_pre_allowance":-1, "death_pre_done":false,
		"toolkit_connections":[], "death_post_allowance":-1}
	if trace.active(): trace.record("damage_begin", {"target":target.get_instance_id(), "kind":kind, "actor":Trace.identity(actor), "player":_pending.player})

func _dispatch_counts() -> Array:
	return [_lib._dispatch_counts.get(CHANNELS[0], 0), _lib._dispatch_counts.get(CHANNELS[1], 0), _lib._dispatch_counts.get(CHANNELS[2], 0)]

func _step(target, death_increment: int = 0, extra_callbacks: int = 0) -> bool:
	if _pending.is_empty(): return false
	if not is_instance_valid(target) or _pending.target.get_ref() != target or target.get_script() != _script:
		_ambiguous("Damage target identity changed."); return false
	if _pending.epoch != _epoch or _lib.seq() != _pending.seq + 1 + extra_callbacks:
		_ambiguous("Damage dispatch or target changed inside the event.")
	_pending.seq = _lib.seq()
	if _death_snapshot() != _pending.death_hooks:
		_ambiguous("Death callback registry changed during damage.")
	var coverage := _coverage()
	if not coverage.is_empty(): _ambiguous(coverage)
	if _lib._developer_mode != _pending.dev: _ambiguous("Developer mode changed during damage.")
	if _pending.dev:
		var now := _dispatch_counts()
		var expected: Array = _pending.dispatch.duplicate()
		expected[2] += death_increment
		if now != expected: _ambiguous("Nested damage bypassed a wrapper.")
		_pending.dispatch = now
	return not _pending.bad

func _death_before(direction, force) -> void:
	if _reading:
		_read_reentry = true
		_ambiguous("Reentrant state inspection triggered Death."); return
	var target = Reader.property(_lib, &"_caller")
	if _pending.is_empty():
		# An unpaired live Death supplies no attacker evidence.
		if target is Object and is_instance_valid(target):
			if target.get_script() == _script and target.get(&"dead") == false:
				_ambiguous("Unpaired Death has no attacker evidence.")
			_seen[target.get_instance_id()] = true
		return
	var matched := _step(target, 1)
	_pending.deaths += 1 # Include repeated Death calls even if already dead.
	if not matched: return
	var allowance := _death_allowance("ai-death-pre")
	var connections = _toolkit_snapshot()
	if allowance < 0 or connections == null:
		_ambiguous("Unverified callback before native death."); return
	_pending.death_pre_allowance = allowance
	_pending.toolkit_connections = connections
	if not _pending.alive: return
	if _pending.deaths != 1 or not _vector(direction) or not _finite(force):
		_ambiguous("Repeated or untyped Death witness."); return
	var expected_vector = _pending.args[2] if _pending.kind == "weapon" else _pending.args[0]
	var expected_force := 10.0 if _pending.kind == "weapon" else 20.0
	var health = target.get(&"health")
	if direction != expected_vector or float(force) != expected_force or not _finite(health) or float(health) != _pending.expected:
		_ambiguous("Death does not match the observed native damage.")
	if target.get(&"dead") != false or (_pending.kind == "weapon" and _pending.expected > 0.0):
		_ambiguous("Death transition contradicts native damage.")

func _death_native_before(direction, force) -> void:
	if _pending.is_empty(): return
	var target = Reader.property(_lib, &"_caller")
	var allowance: int = _pending.death_pre_allowance
	if allowance < 0 or _death_allowance("ai-death-pre") != allowance or _toolkit_snapshot() != _pending.toolkit_connections:
		_ambiguous("Death pre-callback identity or source changed."); return
	# Consume pre-hook callbacks here, never across the native body.
	if not _step(target, 0, allowance): return
	var expected_vector = _pending.args[2] if _pending.kind == "weapon" else _pending.args[0]
	var expected_force := 10.0 if _pending.kind == "weapon" else 20.0
	var health = target.get(&"health")
	if not _vector(direction) or not _finite(force) or direction != expected_vector or float(force) != expected_force or not _finite(health) or float(health) != _pending.expected or target.get(&"dead") != (not _pending.alive):
		_ambiguous("Death pre-callback changed native damage state."); return
	_pending.death_pre_done = true

func _death_native_after(_direction, _force) -> void:
	if _pending.is_empty(): return
	var target = Reader.property(_lib, &"_caller")
	if not _pending.death_pre_done:
		_ambiguous("Native death pre-witness was not completed."); return
	if _death_allowance("ai-death-pre") != _pending.death_pre_allowance or _toolkit_snapshot() != _pending.toolkit_connections:
		_ambiguous("Death pre-callback identity or source changed."); return
	# This is the first post callback. Native Death must still finish at +1.
	# Checking here prevents a temporary registry substitution inside its body
	# from borrowing the trusted callback's later sequence budget.
	if not _step(target): return
	if target.get(&"dead") != true:
		_ambiguous("Death did not complete."); return
	var allowance := _death_allowance("ai-death-post")
	if allowance < 0:
		_ambiguous("Unverified callback inside the death witness."); return
	_pending.death_post_allowance = allowance

func _death_after(_direction, _force) -> void:
	if _pending.is_empty(): return
	var target = Reader.property(_lib, &"_caller")
	var allowance: int = _pending.death_post_allowance
	if allowance < 0 or _death_allowance("ai-death-post") != allowance:
		_ambiguous("Death callback identity or source changed."); return
	if not _step(target, 0, allowance): return
	_pending.death_done = target.get(&"dead") == true
	if not _pending.death_done: _ambiguous("Death did not complete.")
	elif trace.active():
		var owner = _owner.get_ref() if _owner else null
		var root = owner.get_tree().root if is_instance_valid(owner) else null
		for channel in ["ai-death-pre", "ai-death-post"]:
			for row in _pending.death_hooks[channel]:
				var identity := "AIActuallyLoots._on_death@1.2.0" if channel == "ai-death-post" and _trusted_aial_death(row) else Callbacks.identify(row, channel, root, _lib)
				if not identity.is_empty():
					var parts := identity.split("@")
					trace.record("verified_death_callback", {"callback":parts[0], "version":parts[1], "target":target.get_instance_id()})

func _finish(kind: String, actor, args: Array) -> void:
	if _pending.is_empty(): return
	var scene := _scene()
	if _pending.is_empty(): return
	var target = Reader.property(_lib, &"_caller")
	if scene == null or not is_instance_valid(target) or not target is Node or target.is_queued_for_deletion() or not scene.is_ancestor_of(target):
		_ambiguous("Damage target left the live scene.")
		_pending.clear(); return
	if not _step(target):
		_pending.clear(); return
	if kind != _pending.kind or Trace.identity(actor) != _pending.actor_id or args != _pending.args:
		_ambiguous("Damage arguments changed across the event.")
	var health = target.get(&"health")
	var dead = target.get(&"dead")
	if not _finite(health) or float(health) != _pending.expected or not dead is bool:
		_ambiguous("Native damage arithmetic changed.")
	var lethal: bool = _pending.alive and (kind == "explosion" or _pending.expected <= 0.0)
	if lethal != (dead == true and _pending.deaths == 1 and _pending.death_done):
		if _pending.alive: _ambiguous("Missing or extra native death transition.")
	var event := _pending
	_pending = {}
	if dead == true:
		var seen := _seen.has(event.identity)
		_seen[event.identity] = true
		if lethal and not seen and not event.bad and event.player and event.enemy:
			count += 1
			if not _dead and not _menu: visit_count += 1
			if trace.active(): trace.record("accepted", {"target":event.identity, "session":count, "visit":visit_count})
