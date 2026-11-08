extends RefCounted
# RTV 0.2.3.0 / Steam build 26303644; native storage and six damage/death methods.
# Exact Metro 3.4.2 and 3.5.0 output reviewed locally; fail-closed semantics unchanged.
# Independent of other mods, hook masks and unrelated generated methods.
const BLOCKS := {
  "WeaponDamage": "4388c631a28834ad04133067989cd64d37692034e4d853ce2ca298dd9a44be2e",
  "_rtv_vanilla_WeaponDamage": "d03e8fca9ff5eac8c1d1b50f0fb4a7617d857852e5f7e2cb97b93b57f387bc73",
  "ExplosionDamage": "09c55aacdb12e0192b809d201174305e267d671213f811c1b458d45e9729228b",
  "_rtv_vanilla_ExplosionDamage": "00b423561d3257d7e9c02e75a110f38735f6d17555f9466cccb9f48f8b98ff38",
  "Death": "356974b92a9ea6777e5c815edfdea6f4ae2a77bc86f9e004905f2eda33408d6a",
  "_rtv_vanilla_Death": "5d957d65ba3d9813a2aa21eb9d67d27ee48eee599b5b1c9f29a14a44d108611e"
}
# Metro 3.5.0 only renames four wrapper locals; native bodies stay exact.
# Select one complete wrapper family: mixed/unknown generated output is rejected.
const WRAPPERS_350 := {
  "WeaponDamage": "9a8eee1fc9df02389431f2036efb09bd0267f62d9de86b6e0a543fef97c4cfb8",
  "ExplosionDamage": "9ccdaf2672162ad8f6b978198885e6b0515e3aa2a0a5c7cfee3192784dbb9de3",
  "Death": "a51c354a90fa1534f710bf2378355c887ecba73739ed443077794af904e86c95"
}
const HEADER := "076dbec8ce9e1eed907f7f3323f265ef3975d80c61a9ff0c8df446ff2dfacd17"
static var _cached_script: Script
static var _cached_source := ""
static var _cached_valid := false
static func verified(script: Script) -> bool:
	if script == null or not script.has_source_code(): return false
	var source := script.source_code
	if script == _cached_script and source == _cached_source: return _cached_valid
	_cached_script = script
	_cached_source = source
	_cached_valid = _verify(script)
	return _cached_valid
static func _verify(script: Script) -> bool:
	if script == null or not script.has_source_code(): return false
	var source := script.source_code.replace("\r\n", "\n")
	var first := source.find("\nfunc ")
	if first < 0 or source.substr(0, first).strip_edges().sha256_text() != HEADER: return false
	for method in script.get_script_method_list():
		if method.name in ["_get", "_get_property_list"]: return false
	var lines := source.split("\n")
	var expected := BLOCKS.duplicate()
	for name in BLOCKS:
		var start := -1
		var finish := lines.size()
		for i in lines.size():
			if lines[i].begins_with("func " + name + "("):
				if start != -1: return false
				start = i
			elif start >= 0 and lines[i].begins_with("func "):
				finish = i
				break
		if start < 0: return false
		# A later generated section may start with column-zero comments before
		# its next function. Exclude only that trailing trivia, never body code.
		while finish > start and (lines[finish - 1].strip_edges().is_empty() or lines[finish - 1].begins_with("#")):
			finish -= 1
		var digest := "\n".join(lines.slice(start, finish)).strip_edges().sha256_text()
		if name == "WeaponDamage" and digest == WRAPPERS_350[name]:
			expected.merge(WRAPPERS_350, true)
		if digest != expected[name]: return false
	return true

# Script metadata does not call Object._get_property_list. Admit only a plain
# declared field; reject accessor blocks before Object.get can execute them.
const NATIVE_FIELDS := {
 "res://Scripts/AIData.gd": {"field":"faction", "bytecode":"res://Scripts/AIData.gdc", "sha":"fc23baf5f1bfb49e3110e8c36beec6bf670098d15618cc11715e7402d56000a4"},
 "res://Scripts/Sensor.gd": {"field":"type", "bytecode":"res://Scripts/Sensor.gdc", "sha":"21009d3059ac3806c91b12ae165447c770f973d64267a34fb5ef198a2eed51cb"},
}
static func plain_value(object, key: StringName):
	if not object is Object or not is_instance_valid(object): return null
	var script: Script = object.get_script()
	var depth := 0
	while script != null and depth < 8:
		for method in script.get_script_method_list():
			if method.name in ["_get", "_get_property_list"]: return null
		if not script.has_source_code():
			var native: Dictionary = NATIVE_FIELDS.get(script.resource_path, {})
			if native.is_empty() or native.field != String(key): return null
			if ResourceLoader.get_cached_ref(script.resource_path) != script: return null
			if FileAccess.get_sha256(native.bytecode) != native.sha: return null
			return object.get(key)
		if script.source_code.contains('"""') or script.source_code.contains("''' ".strip_edges()):
			return null
		var lines := script.source_code.replace("\r\n", "\n").split("\n")
		var pattern := RegEx.new()
		pattern.compile("^(?:@[^\\n]*?\\s+)?var\\s+" + String(key) + "(?:\\s*:[^:=\\n]+)?\\s*(?::?=[^:;]*)?$")
		for i in lines.size():
			if lines[i].begins_with(" ") or lines[i].begins_with("\t"): continue
			var raw := lines[i].strip_edges()
			if raw.contains("\"") or raw.contains("'"): continue
			var line := raw.split("#")[0].strip_edges()
			if pattern.search(line) == null: continue
			if line.ends_with(":") or line.contains("get =") or line.contains("get:"): return null
			# An indented continuation would be a getter/accessor or unsupported syntax.
			var indent := lines[i].length() - lines[i].lstrip(" \t").length()
			for j in range(i + 1, lines.size()):
				if lines[j].strip_edges().is_empty(): continue
				if lines[j].length() - lines[j].lstrip(" \t").length() > indent: return null
				break
			return object.get(key)
		script = script.get_base_script()
		depth += 1
	return null

static func enum_matches(object, key: String, expected: Dictionary) -> bool:
	if not object is Object or not is_instance_valid(object): return false
	var script: Script = object.get_script()
	var depth := 0
	while script != null and depth < 8:
		var constants := script.get_script_constant_map()
		if constants.has(key): return constants[key] is Dictionary and constants[key] == expected
		script = script.get_base_script()
		depth += 1
	return false
