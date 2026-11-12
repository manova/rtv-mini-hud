extends RefCounted
const Observer = preload("res://rtv-mini-hud/KillObserver.gd")
const AI = preload("res://FakeAI.gd")
class Data extends Resource:
    var menu := false
    var isDead := false
class ConversionTrap extends RefCounted:
    var calls := 0
    var callback: Callable
    func _to_string() -> String:
        calls += 1
        if callback.is_valid(): callback.call()
        return "0.25"
var host: Node
var api: Node
var map: Node3D
var player: Node3D
var npc: Node3D
var observer: RefCounted
var data: Resource
var ids: Array[int] = []
func ok(value: bool, label: String): host.check(value, label)
func fresh() -> void:
    if observer: observer.uninstall()
    for id in ids: api.unhook(id)
    ids.clear()
    data=Data.new()
    observer=Observer.new();observer.sync_state(data);observer.install(host,api,AI)
    ok(observer.read().value=="0","fresh isolated event observer")
func target(faction: int = 1):
    var v=AI.new();v.variant.faction=faction;map.add_child(v);return v
func damage(v, actor, amount=100.0): v.WeaponDamage("Torso",amount,Vector3.FORWARD,actor)
func unavailable(label: String): ok(observer.read().value=="N/A",label)
func run(root: Node, lib: Node, hud: Node, native_ai: Script) -> void:
    host=root;api=lib
    var tree=host.get_tree();var original_scene=tree.current_scene
    hud.set_process(false);hud._kills.uninstall()
    # Let real boot-time deferred work finish before fixture scene swaps.
    var mcm=tree.root.get_node_or_null("MCM");var mcm_process=mcm.is_processing() if mcm else false
    if mcm: mcm.set_process(false)
    for i in 10:
        await tree.process_frame
        # Headless adapter: process_frame above still runs real deferred work.
    host.set_meta("real_frame_results",[{"startupFrames":10}])
    host.set_meta("frame_suppression",{"MCM":mcm_process,"reason":"stub has no Map.Settings; UI not under test"})
    map=Node3D.new();map.name="FixtureMap"
    var core=Node.new();core.name="Core";var camera=Node3D.new();camera.name="Camera"
    player=Node3D.new();player.name="ID";npc=Node3D.new()
    map.add_child(core);core.add_child(camera);camera.add_child(player);map.add_child(npc)
    tree.root.add_child(map);player.add_to_group("Player");tree.current_scene=map
    var rejected=Observer.new();rejected.sync_state(Data.new());rejected.install(host,api)
    ok(rejected._script==native_ai and rejected._valid,"production uses real native resource only")
    rejected.uninstall()
    # Run real Main.apply_config against the modeled native observer while hidden.
    fresh()
    var production_observer = hud._kills
    hud._kills = observer
    var settings = load("res://rtv-mini-hud/Settings.gd")
    var config = settings.defaults()
    var expected_count = 0
    var original_hooks = observer._hooks.duplicate()
    for combo in [[false,false], [false,true], [true,false], [true,true]]:
        for key in ["show_trader_timer", "show_kill_counter"]:
            var entry = config.get_value("Bool", key)
            entry.value = combo[0] if key == "show_trader_timer" else combo[1]
            config.set_value("Bool", key, entry)
        hud.apply_config(config)
        ok(observer == hud._kills and observer._hooks == original_hooks and observer.read().value == str(expected_count), "display settings preserve observer, hooks and count " + str(combo))
        var victim = target()
        damage(victim, player)
        expected_count += 1
        ok(observer.read().value == str(expected_count), "player kill tracked with optional cells " + str(combo))
        damage(victim, player)
        damage(target(), npc)
        ok(observer.read().value == str(expected_count), "corpse and NPC exclusions retained with optional cells " + str(combo))
        hud._panel.present([{"value":"12:34","icon":"sun"}, {"value":"09:42","icon":"user"}, observer.read()])
        ok(hud._panel.values[2].text == str(expected_count) and hud._panel._cells[1].visible == combo[0] and hud._panel._cells[2].visible == combo[1], "latest count and independent visibility delivered " + str(combo))
    hud._kills = production_observer
    hud.apply_config(settings.defaults())
    hud._panel.clear()
    # Focused first-death matrix, each case starts with a fresh numeric observer.
    for trace_enabled in [false,true]:
        for actor_kind in ["player","AI"]:
            for damage_kind in ["weapon","explosion"]:
                fresh()
                observer.trace.configure(trace_enabled)
                var first=target()
                var actor=player if actor_kind=="player" else npc
                var initial=observer.read().value
                if damage_kind=="weapon": damage(first,actor)
                else: first.ExplosionDamage(Vector3.UP,actor)
                var expected="1" if actor_kind=="player" else "0"
                ok(observer.read().value==expected,"first "+actor_kind+" "+damage_kind+" death stays numeric; trace="+str(trace_enabled))
                print("FIRST_DEATH ",JSON.stringify({"actor":actor_kind,"damage":damage_kind,"trace":trace_enabled,"developer_mode":api._developer_mode,"initial":initial,"after":observer.read().value,"reason":observer.reason}))
    fresh()
    var v=target();damage(v,player,30.0)
    ok(observer.read().value=="0" and v.health==70.0 and not v.dead,"nonlethal native damage excluded")
    damage(v,player,70.0)
    ok(observer.read().value=="1" and observer.count==1,"player final blow counted once")
    ok(v.original_calls==2 and v.original_arguments==["Torso",70.0,Vector3.FORWARD,player],"arguments and native call multiplicity unchanged")
    damage(v,player);v.ExplosionDamage(Vector3.FORWARD,player)
    ok(observer.read().value=="1","corpse bullet and explosion repetitions excluded")
    for faction in [0,1,2,3,4]:
        var victim=target(faction);damage(victim,player)
    ok(observer.read().value=="5","Nomad excluded; Bandit Guard Military Boss included")
    var other=target();damage(other,player,20.0);damage(other,npc,80.0)
    ok(observer.read().value=="5","player assist followed by NPC final blow excluded")
    var grenade=target();grenade.ExplosionDamage(Vector3.UP,player)
    ok(observer.read().value=="6","player explosion counted")
    # Anonymous unrelated callbacks and diagnostics are ordinary compatible work.
    ids.append(api.hook("unrelated-ui-pre",func(_value): pass,777))
    var probe_key = "loader_pp" if api.version()=="3.4.2" else "menu_ready"
    var probes_before=Engine.get_meta("_rtv_probe_counts",{}).get(probe_key,0)
    for i in 25:
        api._dispatch("unrelated-ui-pre",[i])
        if api._developer_mode:
            if api.version()=="3.4.2": api._dispatch("loader-_physics_process-pre",[0.016])
            else: api._dispatch("menu-_ready-pre",[])
    if api._developer_mode: ok(Engine.get_meta("_rtv_probe_counts",{}).get(probe_key,0)>=probes_before+25,"real released anonymous diagnostic actually executed")
    damage(target(),player)
    ok(observer.read().value=="7","unrelated anonymous callbacks and real released diagnostics accepted")
    ids.append(api.hook("ai-weapondamage-pre",func(_h,_d,_v,_a): pass,0))
    ids.append(api.hook("ai-weapondamage-post",func(_h,_d,_v,_a): pass,0))
    damage(target(),player)
    ok(observer.read().value=="8","ordinary pre/post outside native witness interval compose")
    # Load attempts and actual lifecycle boundaries, independent of MSS identity.
    api._dispatch("loader-resetcharacter-pre",[])
    unavailable("reset attempt does not claim a completed visit")
    var old_player=player;camera.remove_child(old_player);old_player.free()
    player=Node3D.new();player.name="ID";camera.add_child(player);player.add_to_group("Player")
    ok(observer.read().value=="0" and observer.count==8,"actual player identity change resets visit, keeps session")
    damage(target(),player);data.isDead=true;observer.sync_state(data)
    ok(observer.read().value=="0" and observer.count==9,"death resets visit only")
    data.isDead=false;data.menu=true;observer.sync_state(data);data.menu=false;observer.sync_state(data)
    observer.cumulative=true
    ok(observer.read().value=="9","session deliberately spans load/death boundaries")
    observer.cumulative=false
    var environmental=target();environmental.Death(Vector3.UP,20.0);damage(environmental,player)
    unavailable("unpaired live Death has no attacker evidence")
    ok(observer.count==9,"unpaired Death does not invent credit")
    fresh()
    var revived_between=target();damage(revived_between,player)
    revived_between.dead=false;revived_between.health=100.0;damage(revived_between,player)
    unavailable("same-entity revival between events is explicitly unsupported")
    ok(observer.count==1,"revival does not silently invent or hide a second confirmed total")
    fresh()
    # Unknown combat replacements block only this feature, not mod execution.
    ids.append(api.hook("ai-weapondamage",func(_h,_d,_v,_a): pass,0))
    var replacement_target=target();damage(replacement_target,player)
    unavailable("damage replacement reports unavailable")
    ok(replacement_target.dead,"observer never suppresses another mod or native damage")
    fresh()
    ids.append(api.hook("ai-death",func(_d,_f): pass,0))
    damage(target(),player);unavailable("Death replacement reports unavailable")
    for channel in ["ai-weapondamage-pre","ai-weapondamage-post","ai-death-pre","ai-death-post"]:
        fresh()
        var priority=Observer.LATE if channel.ends_with("pre") and channel!="ai-death-pre" or channel=="ai-death-post" else Observer.EARLY
        var cb=func(_h,_d,_v,_a): pass
        if channel.begins_with("ai-death"): cb=func(_d,_f): pass
        ids.append(api.hook(channel,cb,priority));unavailable("tie/crossing boundary rejected "+channel)
    fresh()
    ids.append(api.hook("helper-event-pre",func(): pass,0))
    var helper_target=target();helper_target.helper=func(): api._dispatch("helper-event-pre",[])
    damage(helper_target,player);unavailable("foreign dispatch during damage makes event ambiguous")
    ok(observer.count==0,"ambiguous event never invents a kill")
    helper_target.helper=Callable();damage(target(),player)
    unavailable("missing event leaves visit total incomplete")
    observer._reset_visit("fixture_new_visit",true)
    ok(observer.read().value=="0","new visit can recover explicit visit scope")
    observer.cumulative=true;unavailable("incomplete process scope never resurrected")
    fresh()
    var nested=target();nested.helper=func():
        nested.helper=Callable();damage(nested,npc)
    damage(nested,player,0.0)
    unavailable("prior delayed-conversion same-wrapper NPC theft rejected")
    ok(observer.count==0 and nested.original_calls==2,"same-wrapper nested NPC call remains native and uncredited")
    if api._developer_mode:
        fresh()
        var delayed=target();delayed.helper=func():
            delayed.helper=Callable();damage(delayed,npc)
        var conversion=ConversionTrap.new()
        conversion.callback=func(): damage.bind(delayed,player,0.0).call_deferred()
        var first_args: Dictionary=Engine.get_meta("_rtv_probe_first_args",{})
        var saved=first_args.duplicate();first_args.erase("camera_pp")
        # 3.5.0 removed the argument-stringifying camera probe. Retain the
        # observer regression with an explicit fixture, not a claimed released probe.
        if api.version()=="3.5.0":
            ids.append(api.hook("camera-_physics_process-pre",func(value): var rendered = str(value),100))
        api._dispatch("camera-_physics_process-pre",[conversion])
        await tree.process_frame
        await tree.process_frame
        ok(conversion.calls==1,"legacy probe/explicit fixture converted the Object once")
        unavailable("later queued damage from diagnostic conversion cannot steal NPC kill")
        ok(observer.count==0 and delayed.original_calls==2,"deferred conversion regression retains correct no-credit outcome")
        Engine.set_meta("_rtv_probe_first_args",saved)
    fresh()
    var revived=target();revived.helper=func():
        revived.helper=Callable();revived.health+=50.0;damage(revived,npc,50.0)
    damage(revived,player,100.0)
    unavailable("revival and same-method NPC finishing rejected")
    ok(observer.count==0 and revived.death_calls==2,"duplicate Death witnesses retained despite already-dead state")
    fresh()
    var cross=target();cross.helper=func():
        cross.helper=Callable();cross.ExplosionDamage(Vector3.FORWARD,npc)
    damage(cross,player,0.0);unavailable("nested cross-method NPC death rejected")
    fresh()
    var double_death=target();double_death.helper=func(): double_death.Death(Vector3.FORWARD,10.0)
    damage(double_death,player);unavailable("multiple direct Death entries rejected")
    fresh()
    var trap=ConversionTrap.new();observer.trace.configure(true)
    # Explicit callback invocation simulates an unsupported variant before a
    # wrapper can coerce it; no native method receives malformed arguments.
    var typed_target=target();api._caller=typed_target
    api._wrapper_active[str(typed_target.get_instance_id())+":ai-explosiondamage"]=true
    observer._explosion_before(trap,player)
    api._wrapper_active.clear();api._caller=null
    ok(trap.calls==0,"observer and enabled trace never stringify arbitrary arguments")
    unavailable("unsupported raw argument rejected without conversion")
    fresh()
    # Hooks can change after installation; feature revalidates its own boundary.
    api.unhook(observer._hooks[0]);unavailable("runtime observer loss detected")
    fresh()
    var empty_target=target();empty_target.helper=func(): api.unhook(observer._hooks[1])
    damage(empty_target,player);unavailable("lost post observer leaves unavailable coverage")
    fresh()
    var resetting=target();resetting.helper=func(): api._dispatch("loader-loadcharacter-pre",[])
    damage(resetting,player);unavailable("load attempt during damage keeps visit incomplete")
    ok(observer.count==0,"lifecycle interruption is uncredited")
    fresh()
    var dying=target();dying.helper=func(): data.isDead=true
    damage(dying,player);unavailable("death flag changed inside damage remains incomplete")
    fresh()
    var removed=target();removed.helper=func(): removed.queue_free()
    damage(removed,player);unavailable("queued victim cannot provide completed observation")
    fresh()
    observer.sync_state(Resource.new());unavailable("missing lifecycle flags never expose a clean number")
    fresh()
    # Captured live order: scene/player already stable, Compiler.Spawn later
    # invokes asynchronous LoadCharacter. A character restore is not a visit.
    await tree.process_frame
    var observed_before=observer.read().duplicate()
    api._dispatch("loader-loadcharacter-pre",[])
    var observed_after=observer.read().duplicate()
    ok(observed_after.value=="0","captured order: stable scene then LoadCharacter preserves numeric zero")
    await tree.process_frame
    damage(target(),player)
    ok(observer.read().value=="1" and observer.count==1,"captured order: accepted player kill remains visibly one")
    api._dispatch("loader-loadcharacter-pre",[])
    ok(observer.read().value=="1" and observer.count==1,"same-identity character restore neither resets nor poisons count")
    host.set_meta("captured_lifecycle_replay",{"before":observed_before,"afterCharacterPre":observed_after,"afterKill":observer.read().duplicate()})
    fresh()
    observer._ambiguous("fixture missing event")
    api._dispatch("loader-loadcharacter-pre",[])
    unavailable("character restore never heals an incomplete visit")
    observer.cumulative=true
    unavailable("character restore never heals an incomplete process")
    fresh()
    for channel in ["loader-loadscene-pre","loader-newgame-pre","loader-resetcharacter-pre"]:
        if channel=="loader-loadscene-pre":api._dispatch(channel,["Cabin"])
        elif channel=="loader-newgame-pre":api._dispatch(channel,[1,0])
        else:api._dispatch(channel,[])
        unavailable("transition intent remains unavailable without new identity "+channel)
        api._dispatch("loader-loadcharacter-pre",[])
        unavailable("character restore cannot clear transition intent "+channel)
        fresh()
    var native_contract=load("res://rtv-mini-hud/NativeAIContract.gd")
    for body in [
        "extends Node\nvar reads=0\nvar type:int=0:get=read_type\nfunc read_type():\n reads+=1\n return 0\n",
        "extends Node\nvar reads=0\nvar type: int:\n get:\n  reads+=1\n  return 0\nfunc decoy():\n var type=0\n return type\n",
        "extends Node\nvar reads=0\nvar type=0\nfunc _get_property_list () -> Array:\n reads+=1\n return []\n"
    ]:
        var guarded=GDScript.new();guarded.source_code=body
        ok(guarded.reload()==OK,"getter/enumerator fixture compiles")
        var custom=guarded.new()
        ok(native_contract.plain_value(custom,&"type")==null and custom.reads==0,"custom getter/enumerator rejected before execution")
        custom.free()
    var start=Time.get_ticks_usec()
    for i in 30: damage(target(),player)
    var elapsed=Time.get_ticks_usec()-start
    ok(observer.read().value=="30","thirty independent observed kills")
    host.set_meta("observation_timing",{"events":30,"microseconds":elapsed,"syntheticBody":true})
    # Real frames preserve valid diagnostics outside a pending synchronous event.
    for i in 3:
        await tree.process_frame
        # Headless adapter: process_frame above still runs real deferred work.
    ok(observer.read().value=="30","real frame work outside event does not invalidate counter")
    fresh()
    observer.uninstall();observer=null
    tree.current_scene=original_scene;map.free()
    # Restore real HUD's instance with production-only native contract.
    hud._kills=Observer.new();hud._kills.sync_state(hud._game_data);hud._kills.install(hud,lib)
    ok(hud._kills.read().value=="0","restored production observer remains numeric")
    var original=ResourceLoader.get_cached_ref("res://Scripts/AI.gd")
    var changed=GDScript.new();changed.source_code="extends Node3D\n";ok(changed.reload()==OK,"cache replacement compiles")
    changed.take_over_path("res://Scripts/AI.gd")
    ok(hud._kills.read().value=="N/A","production AI resource takeover is unavailable")
    original.take_over_path("res://Scripts/AI.gd")
    ok(hud._kills.read().value=="N/A","coverage gap does not restore an incomplete total")
    if mcm: mcm.set_process(mcm_process)
