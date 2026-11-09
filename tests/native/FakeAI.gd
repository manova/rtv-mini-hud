extends Node3D
const FactionData = preload("res://FixtureVariant.gd")
const EnemySensor = preload("res://FixtureSensor.gd")
var variant := FactionData.new()
var sensor := EnemySensor.new()
var health := 100.0
var dead := false
var container: Node3D
var looting := false
var death_helper: Callable
var helper: Callable
var original_calls := 0
var original_arguments: Array = []
var death_calls := 0
func _init(): add_child(sensor)
func _rtv_vanilla_WeaponDamage(hitbox: String, damage: float, vector: Vector3, id: Node3D):
	original_calls += 1
	original_arguments = [hitbox,damage,vector,id]
	if dead: return
	health -= damage
	if helper.is_valid(): helper.call()
	if health <= 0: Death(vector,10.0)
func _rtv_vanilla_ExplosionDamage(direction, id: Node3D):
	original_calls += 1
	original_arguments = [direction,id]
	Death(direction,20.0)
func _rtv_vanilla_Death(_direction, _force):
	death_calls += 1
	dead = true
	if death_helper.is_valid(): death_helper.call()

func WeaponDamage(hitbox: String, damage: float, vector: Vector3, id: Node3D):
	if not Engine.has_meta("RTVModLib"):
		_rtv_vanilla_WeaponDamage(hitbox, damage, vector, id)
		return
	var _lib = Engine.get_meta("RTVModLib")
	if not _lib._any_mod_hooked:
		_rtv_vanilla_WeaponDamage(hitbox, damage, vector, id)
		return
	if not _lib._hooked_bases.has("ai-weapondamage"):
		_rtv_vanilla_WeaponDamage(hitbox, damage, vector, id)
		return
	if _lib._developer_mode:
		_lib._dispatch_counts["ai-weapondamage"] = int(_lib._dispatch_counts.get("ai-weapondamage", 0)) + 1
	var _rtv_wa_key: String = str(get_instance_id()) + ":ai-weapondamage"
	if _lib._wrapper_active.has(_rtv_wa_key):
		_rtv_vanilla_WeaponDamage(hitbox, damage, vector, id)
		return
	_lib._wrapper_active[_rtv_wa_key] = true
	var _rtv_prev_caller = _lib._caller
	_lib._caller = self
	_lib._dispatch("ai-weapondamage-pre", [hitbox, damage, vector, id])
	var _repl = _lib._get_hooks("ai-weapondamage")
	if _repl.size() > 0:
		var _prev_skip = _lib._skip_super
		_lib._skip_super = false
		_repl[0].callv([hitbox, damage, vector, id])
		var _did_skip = _lib._skip_super
		_lib._skip_super = _prev_skip
		if !_did_skip:
			_rtv_vanilla_WeaponDamage(hitbox, damage, vector, id)
	else:
		_rtv_vanilla_WeaponDamage(hitbox, damage, vector, id)
	_lib._caller = self
	_lib._dispatch("ai-weapondamage-post", [hitbox, damage, vector, id])
	_lib._dispatch_deferred("ai-weapondamage-callback", [hitbox, damage, vector, id])
	_lib._wrapper_active.erase(_rtv_wa_key)
	_lib._caller = _rtv_prev_caller

func ExplosionDamage(direction, id: Node3D):
	if not Engine.has_meta("RTVModLib"):
		_rtv_vanilla_ExplosionDamage(direction, id)
		return
	var _lib = Engine.get_meta("RTVModLib")
	if not _lib._any_mod_hooked:
		_rtv_vanilla_ExplosionDamage(direction, id)
		return
	if not _lib._hooked_bases.has("ai-explosiondamage"):
		_rtv_vanilla_ExplosionDamage(direction, id)
		return
	if _lib._developer_mode:
		_lib._dispatch_counts["ai-explosiondamage"] = int(_lib._dispatch_counts.get("ai-explosiondamage", 0)) + 1
	var _rtv_wa_key: String = str(get_instance_id()) + ":ai-explosiondamage"
	if _lib._wrapper_active.has(_rtv_wa_key):
		_rtv_vanilla_ExplosionDamage(direction, id)
		return
	_lib._wrapper_active[_rtv_wa_key] = true
	var _rtv_prev_caller = _lib._caller
	_lib._caller = self
	_lib._dispatch("ai-explosiondamage-pre", [direction, id])
	var _repl = _lib._get_hooks("ai-explosiondamage")
	if _repl.size() > 0:
		var _prev_skip = _lib._skip_super
		_lib._skip_super = false
		_repl[0].callv([direction, id])
		var _did_skip = _lib._skip_super
		_lib._skip_super = _prev_skip
		if !_did_skip:
			_rtv_vanilla_ExplosionDamage(direction, id)
	else:
		_rtv_vanilla_ExplosionDamage(direction, id)
	_lib._caller = self
	_lib._dispatch("ai-explosiondamage-post", [direction, id])
	_lib._dispatch_deferred("ai-explosiondamage-callback", [direction, id])
	_lib._wrapper_active.erase(_rtv_wa_key)
	_lib._caller = _rtv_prev_caller

func Death(direction, force):
	if not Engine.has_meta("RTVModLib"):
		_rtv_vanilla_Death(direction, force)
		return
	var _lib = Engine.get_meta("RTVModLib")
	if not _lib._any_mod_hooked:
		_rtv_vanilla_Death(direction, force)
		return
	if not _lib._hooked_bases.has("ai-death"):
		_rtv_vanilla_Death(direction, force)
		return
	if _lib._developer_mode:
		_lib._dispatch_counts["ai-death"] = int(_lib._dispatch_counts.get("ai-death", 0)) + 1
	var _rtv_wa_key: String = str(get_instance_id()) + ":ai-death"
	if _lib._wrapper_active.has(_rtv_wa_key):
		_rtv_vanilla_Death(direction, force)
		return
	_lib._wrapper_active[_rtv_wa_key] = true
	var _rtv_prev_caller = _lib._caller
	_lib._caller = self
	_lib._dispatch("ai-death-pre", [direction, force])
	var _repl = _lib._get_hooks("ai-death")
	if _repl.size() > 0:
		var _prev_skip = _lib._skip_super
		_lib._skip_super = false
		_repl[0].callv([direction, force])
		var _did_skip = _lib._skip_super
		_lib._skip_super = _prev_skip
		if !_did_skip:
			_rtv_vanilla_Death(direction, force)
	else:
		_rtv_vanilla_Death(direction, force)
	_lib._caller = self
	_lib._dispatch("ai-death-post", [direction, force])
	_lib._dispatch_deferred("ai-death-callback", [direction, force])
	_lib._wrapper_active.erase(_rtv_wa_key)
	_lib._caller = _rtv_prev_caller
