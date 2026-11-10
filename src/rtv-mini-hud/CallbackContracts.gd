extends RefCounted
# Versioned VTK observation surface and legacy source-pinned bookkeeping.
# This is compatibility validation, not
# a sandbox against arbitrary in-process code modification. No VTK attribution method
# is called to establish a kill, and no other mod's kill totals are imported.
const SOURCES := {
  "res://mods/VTK/VTKConfig.gd": "97c0276de32c2794ec9598051a0b98b91935fb9f8f065b384fafb28277df599e",
  "res://mods/VTK/VTKData.gd": "2cedddbbd4d05661c944f31463d283761348db067db54ae53897750677ab6d08",
  "res://mods/VTK/VTKDeposits.gd": "8aecdf89cc7b7d311c7d9331b46788c59ce98b498eda89f13aaae28b73970971",
  "res://mods/VTK/VTKDraft.gd": "f01d940ee0fdf7aebbd229a94cda9cba566919d163a5877fe3cfe2d20a509e40",
  "res://mods/VTK/VTKEditor.gd": "953533be3a95457d80c142bdc73c71d7d2aea6a907637e632204d19632dcc25c",
  "res://mods/VTK/VTKEquip.gd": "b0f9fb711beb2eb75dbf707557228f9afe8af614d7348fd99bb79af68430422c",
  "res://mods/VTK/VTKFeatureHost.gd": "e8d0fd8d63dbeaeabe1ddfe5c69e2d7cb70ee619a0285bdb8bbc4f633c30925b",
  "res://mods/VTK/VTKFeed.gd": "a76e0d2c707d1883d13f87e36e12eb75f72fc0190cad85519014d147e8836692",
  "res://mods/VTK/VTKHooks.gd": "01d0b03a740fe726c517e8bae569ade9c8865f4e5c6c550c5af3646e442368d0",
  "res://mods/VTK/VTKHud.gd": "835d22fb5476d82177994cd9c40998d68a44f8202bdf31159e3b3bf1f6afa0e0",
  "res://mods/VTK/VTKItemStore.gd": "3267854b94ed2a271f22ffc3e5279f95d07b0027a9a12796a1c0c4471a557db0",
  "res://mods/VTK/VTKKillCounter.gd": "60fb75775d7b0449d8a445403a0d52f3147fe8c6d258fb4c1554498a4c1beee0",
  "res://mods/VTK/VTKLoadoutSession.gd": "c235a73f8a0147d8b1c621019f1bf47f13b54ffa2189fc512ff527dd04db9fdf",
  "res://mods/VTK/VTKLoc.gd": "cd584d5347f7311d5c093799f3ee3d679155a6295983f14e0f0a6cfab4cbbd95",
  "res://mods/VTK/VTKLog.gd": "e39a284d50261bf9f3073143644f7644508f4b13e33f9a802866a678383e4479",
  "res://mods/VTK/VTKLook.gd": "7eaf108aab63ad86a6940327ca30afcbed9e5d318e1c0ac57715320283ac0811",
  "res://mods/VTK/VTKMCMBridge.gd": "25bd7a9b4a2f167cbe42f78f91fe98bc1e1458fe11b6bb944e9132a40edc8899",
  "res://mods/VTK/VTKNotes.gd": "d03ddc1b093b7a0c6ab3f956ed38220b070887ead63afd75c2dbd43f977f580d",
  "res://mods/VTK/VTKPaths.gd": "034ba755a63c31652adceb4b3e39c137bce5d8503e423a224a43c4ab9a11d06c",
  "res://mods/VTK/VTKPicker.gd": "1a91a78422d5b7dff8eb22430f59823a15e25c70a43f5874cfb73aa9c31bc72b",
  "res://mods/VTK/VTKRefresh.gd": "7a28c7f9f7e605160cddeae0bd20ef6b8de65acaee688b6cd921ecd260eecc20",
  "res://mods/VTK/VTKSeasonDriver.gd": "0c2d13a8c548705abead187509136c0ac4159e0f6d1617a810845cbb0deef78c",
  "res://mods/VTK/VTKSeasons.gd": "3d80f2adee169295a4650002d3befd8eb3f96c4f762205feef7844fc7a10301a",
  "res://mods/VTK/VTKSetsRail.gd": "b33a902ab45a933d9040f349a941407b5bbed01b7f8a7a4c9b5e4efae125d176",
  "res://mods/VTK/VTKSurface.gd": "8b2be51353607640823cd5dbe996ee3caaa9899a4eefc2caacc9be592a6dc62a",
  "res://mods/VTK/VTKTeleportTab.gd": "efbfd1b98f1de5006964a332ea152b8dbc9075855b89506cf6c27d9ff45d8aa9",
  "res://mods/VTK/VTKTravel.gd": "c10a1b85ea3144fb4689ac29052ea8f922fc650248cf57c7e496cda842f01bed",
  "res://mods/VTK/VTKUI.gd": "47b6786b8a091ac5061c1e3a9dbbcac1e2c32ad1a14fece9b64982f28c177aeb",
  "res://MurdieLavaLamps/BrokenLamp.gd": "2fc1cf8743178a1bd9c1e0ec27f1a3a5ce2b8452181796bdbdf1ff6d8b4e8427",
  "res://MurdieLavaLamps/CoopLink.gd": "aece2c0718b96d9d6f7308aa1e221d5eb05b6d5539a540d6287a07240a1e7c87",
  "res://MurdieLavaLamps/GlassShadow.gd": "861a53ced48c4d00b16d00d3c3178f8b0bb1c9bb615ee13fa59083406fd3e3d7",
  "res://MurdieLavaLamps/LampData.gd": "31efbc77395e90dbc87d2f738a5bd35d772e8208dca91d5ad169591d46118a01",
  "res://MurdieLavaLamps/LampInside.gd": "8677ec9685716f1cb8812df2c0c6533574d6e8bda47ada8beafea18f063e532b",
  "res://MurdieLavaLamps/LampModel.gd": "dcd894996f699997cb4d4e7027d983eccf2f42e473a4dd1c88e6954a9cb9c9ba",
  "res://MurdieLavaLamps/LampState.gd": "37397990a24b1268b2519f67bb3d3d83d31ea540a6939f68f28422c877ee63cb",
  "res://MurdieLavaLamps/LampWax.gd": "c0d098fb508a72f5d90a0b78f2c99375eca3f3766b0841d37a7710ff0358187f",
  "res://MurdieLavaLamps/LavaLamp.gd": "78a9a10299acf60a6a7eae5c44532e2bc71753748c22e43797078274623d2937",
  "res://MurdieLavaLamps/Main.gd": "1e952485e19efc1a910babd18535ca3a0af4e79b6d4dc662034162a865707050",
  "res://MurdieLavaLamps/rtvkit/Settings.gd": "1f7b4f7d050d70344892e3030788b69bdd2cd851c9c47bcb21a4994785e883a8"
}

# These source-defined inner classes have no separate source/path in Godot.
const INNER_CLASSES := {
  "res://mods/VTK/VTKEditor.gd": [
    "ChosenRow",
    "ToggleSwitch"
  ],
  "res://mods/VTK/VTKHud.gd": [
    "Ticker"
  ],
  "res://mods/VTK/VTKSetsRail.gd": [
    "CreateCard"
  ],
  "res://MurdieLavaLamps/LampData.gd": [
    "Blob"
  ]
}

# Cache only hashing work, never owner, dependency, signal, or registry trust.
# The current source string and path are compared on every witness.
static var _source_hashes: Dictionary = {}
static func _source_matches(script: Script) -> bool:
	var path := script.resource_path
	var source := script.source_code
	if not SOURCES.has(path): return false
	var previous: Dictionary = _source_hashes.get(script, {})
	if not previous.is_empty() and previous.path == path and previous.source == source:
		return previous.valid
	var valid: bool = source.replace("\r\n", "\n").sha256_text() == SOURCES[path]
	_source_hashes[script] = {"path":path,"source":source,"valid":valid}
	return valid

static func _script(script: Script, seen: Dictionary) -> bool:
	if script == null or not script.has_source_code(): return false
	var path := script.resource_path
	if not _source_matches(script): return false
	if seen.has(script): return true
	seen[script] = true
	var base := script.get_base_script()
	if base != null and not _script(base, seen): return false
	# Check actual preloaded Script objects, not merely the current path cache.
	var constants := script.get_script_constant_map()
	for name in constants:
		var value = constants[name]
		if value is Script:
			# Only explicit class declarations in this pinned parent qualify.
			if value.resource_path.is_empty() and not value.has_source_code():
				var declaring := script
				var declared := false
				while declaring != null:
					if name in INNER_CLASSES.get(declaring.resource_path, []) and declaring.get_script_constant_map().get(name) == value:
						declared = true; break
					declaring = declaring.get_base_script()
				if not declared or not _inner_dependencies(value, seen): return false
				continue
			if not _script(value, seen): return false
	return true

static func _inner_dependencies(script: Script, seen: Dictionary) -> bool:
	if seen.has(script): return true
	seen[script] = true
	var base := script.get_base_script()
	if base != null and not _script(base, seen): return false
	for value in script.get_script_constant_map().values():
		if value is Script and not _script(value, seen): return false
	return true

# Node and loaded Script identity remain live checks in both trust modes.
static func _owner_shape(owner, root: Node, path: String, source: String) -> bool:
	if not owner is Node or not is_instance_valid(owner) or root == null: return false
	if root.get_node_or_null(NodePath(path)) != owner or owner.is_queued_for_deletion(): return false
	var script: Script = owner.get_script()
	return script != null and script.resource_path == source

static func _owner(owner, root: Node, path: String, source: String) -> bool:
	return _owner_shape(owner, root, path, source) and _script(owner.get_script(), {})

# Missing marker means legacy only. An explicit unknown marker never falls back.
# The contract is an interoperability promise, not proof of arbitrary code safety.
static func toolkit_mode(owner: Node) -> String:
	var script: Script = owner.get_script()
	if script == null: return ""
	var constants := script.get_script_constant_map()
	if constants.has("OBSERVER_CONTRACT"):
		var version = constants.OBSERVER_CONTRACT
		return "contract-v1" if typeof(version) == TYPE_INT and version == 1 else ""
	return "legacy-5.5.1" if _script(script, {}) else ""

static func _toolkit_surface(owner: Node, lib: Object) -> bool:
	var registry = lib.get("_hooks")
	if not registry is Dictionary: return false
	var methods := {
		"ai-weapondamage-pre":"_on_ai_weapon_damage",
		"ai-explosiondamage-pre":"_on_ai_explosion",
		"ai-death-pre":"_on_ai_death"
	}
	for channel in methods:
		var rows = registry.get(channel, [])
		if not rows is Array: return false
		var found := 0
		for row in rows:
			if not row is Dictionary or not row.get("callback") is Callable: return false
			var cb: Callable = row.callback
			if cb.get_object() != owner: continue
			if row.get("priority") != 100 or cb != Callable(owner, methods[channel]): return false
			found += 1
		if found != 1: return false
	for channel in ["ai-weapondamage", "ai-explosiondamage", "ai-death"]:
		var rows = registry.get(channel, [])
		if not rows is Array or not rows.is_empty(): return false
	return owner.has_signal("kill_event")

static func toolkit_connections(owner: Node, root: Node) -> Variant:
	var mode := toolkit_mode(owner)
	if mode.is_empty() or not owner.has_signal("kill_event"): return null
	var rows := owner.get_signal_connection_list("kill_event")
	if rows.size() > 1: return null
	var copied := []
	for row in rows:
		var cb: Callable = row.callable
		if row.flags != 0 or not cb.is_valid(): return null
		var feed = cb.get_object()
		if not _owner_shape(feed, root, "VTKKC_Canvas/VTKFeed", "res://mods/VTK/VTKFeed.gd"): return null
		if mode == "legacy-5.5.1" and not _script(feed.get_script(), {}): return null
		if cb != Callable(feed, "_on_kill_event") or feed.get("_hooks") != owner: return null
		copied.append({"callable":cb,"flags":row.flags})
	return copied

static func identify(row: Dictionary, channel: String, root: Node, lib: Object) -> String:
	var cb: Callable = row.callback
	if row.priority != 100 or not cb.is_valid(): return ""
	var owner = cb.get_object()
	if channel == "ai-death-pre":
		if not _owner_shape(owner, root, "VTKUI/VTKHooks", "res://mods/VTK/VTKHooks.gd"): return ""
		if cb != Callable(owner, "_on_ai_death") or owner.get("_lib") != lib: return ""
		var mode := toolkit_mode(owner)
		if mode.is_empty(): return ""
		if mode == "legacy-5.5.1":
			# Legacy feed dynamically calls this helper; retain its exact source gate.
			var ui := root.get_node_or_null("VTKUI")
			if not _owner(ui, root, "VTKUI", "res://mods/VTK/VTKUI.gd"): return ""
		elif not _toolkit_surface(owner, lib): return ""
		if toolkit_connections(owner, root) == null: return ""
		return "VostokToolkit._on_ai_death@5.5.1" if mode == "legacy-5.5.1" else "VostokToolkit._on_ai_death@contract-v1"
	if channel != "ai-death-post": return ""
	if _owner(owner, root, "MurdieLavaLamps", "res://MurdieLavaLamps/Main.gd"):
		if cb == Callable(owner, "_ai_died") and owner.get("_lib") == lib:
			return "MurdieLavaLamps._ai_died@1.1.2"
	return ""
