extends Node
var lib: Node
var checks: Array = []
func check(ok: bool, label: String):
	checks.append({"passed":ok,"check":label})
	if not ok: push_error(label)
func _ready(): run.call_deferred()
func run():
	var phase = OS.get_cmdline_user_args()[0]
	var case_name = OS.get_cmdline_user_args()[1]
	var config = JSON.parse_string(FileAccess.get_file_as_string("user://case.json"))
	var broad: bool = config.registry
	var aial: bool = config.aial
	var expected: int = config.count
	check(OS.get_user_data_dir().replace("\\", "/") == String(config.userdata).replace("\\", "/"), "isolated profile")
	if not checks[-1].passed: finish(); return
	check(Engine.get_version_info().hex == 0x040603, "native engine 4.6.3")
	check(ProjectSettings.load_resource_pack(OS.get_executable_path().get_base_dir()+"/RTV.pck", false), "installed game pack mounted without gameplay")
	lib=load("res://modloader.gd").new();lib._has_loaded=true;lib.name="ModLoader";get_tree().root.add_child(lib)
	lib._register_rtv_modlib_meta();lib._compile_regex();lib._build_class_name_lookup();lib._enumerate_game_scripts()
	lib._load_developer_mode_setting();lib._ui_mod_entries=lib.collect_mod_metadata();lib._load_ui_config();lib.load_all_mods();lib._apply_script_overrides()
	check(lib._loaded_mod_ids.size()==expected,"exact requested mod stack: "+str(expected))
	check(lib._any_mod_declared_registry==broad,"registry opt-in matches requested stack")
	if phase=="generate":
		var generated=lib._generate_hook_pack(true)
		check(not generated.is_empty(),"fresh Metro generation")
		var z=ZIPReader.new();check(z.open(generated)==OK,"generated pack readable")
		var f=FileAccess.open("user://AI-generated.gd.txt",FileAccess.WRITE);f.store_buffer(z.read_file("Scripts/AI.gd"));f.close();z.close()
		var archives=lib._collect_enabled_archive_paths();var sections=lib._build_autoload_sections()
		check(lib._write_pass_state(archives,lib._compute_state_hash(archives,sections.prepend))==OK,"fresh pass state")
		check(lib._hook_pack_demotions.is_empty(),"no demoted hooks")
	else:
		var database=get_tree().root.get_node("Database");database.set_script(load("res://Scripts/Database.gd"));database.set_process(false);database.set_physics_process(false)
		check(lib._finish_boot(false),"mod autoload and framework initialization")
		get_tree().paused=false
		var hud=get_tree().root.get_node_or_null("RtvMiniHud")
		check(hud!=null,"HUD autoload")
		var mcm = get_tree().root.get_node_or_null("MCM")
		if mcm: mcm.set_process(false)
		hud.set_process(false)
		for i in 10: await get_tree().process_frame
		var toolkit = get_tree().root.get_node_or_null("VTKUI/VTKHooks")
		if config.toolkit:
			check(toolkit != null, "actual Toolkit Hooks node initialized")
			if toolkit:
				toolkit._try_register()
				check(toolkit._registered, "actual Toolkit hooks registered")
				var found := false
				for row in lib._hooks.get("ai-death-pre", []):
					if row.callback == Callable(toolkit, "_on_ai_death"): found = true
				check(found, "actual Toolkit Death pre callback present")
		if config.lava:
			var lamp = get_tree().root.get_node_or_null("MurdieLavaLamps")
			check(lamp != null, "actual Lava Lamps autoload initialized")
			var found := false
			for row in lib._hooks.get("ai-death-post", []):
				if row.callback == Callable(lamp, "_ai_died"): found = true
			check(found, "actual Lava Lamps Death post callback present")
		var actual: Script=load("res://Scripts/AI.gd")
		var contract=load("res://rtv-mini-hud/NativeAIContract.gd")
		check(contract.verified(actual),"candidate accepts actual generated native contract")
		check(load("res://BaselineContract.gd").verified(actual)==broad,"released verifier distinguishes minimal and registry layouts")
		var after_death:=actual.source_code.substr(actual.source_code.find("\nfunc Death("))
		var next_func:=after_death.find("\nfunc ",2)
		check(after_death.substr(next_func).begins_with("\nfunc UpdateStatus(" if broad else "\nfunc _rtv_apply_ai_loadouts("),"next function after Death matches layout mechanism")
		check(hud._kills._valid and hud._kills._hooks.size()==12,"production observer registers twelve hooks")
		check(hud._kills.read().value=="0","production initial numeric zero")
		check(lib._developer_mode==case_name.ends_with("-dev"),"requested developer mode")
		for child in get_tree().root.get_children():
			if child != self: child.process_mode = Node.PROCESS_MODE_DISABLED
		load("res://ContractTests.gd").new().run(self,contract)
		await load("res://GeneralizedTests.gd").new().run(self,lib,hud,actual)
		if aial: await load("res://AIALTests.gd").new().run(self,lib,hud)
		if config.toolkit or config.lava:
			await load("res://CompatibilityTests.gd").new().run(self,lib,hud)
	finish.call_deferred()
func finish():
	var passed=true
	for row in checks:passed=passed and row.passed
	var result={"passed":passed,"checks":checks}
	var f=FileAccess.open("user://"+OS.get_cmdline_user_args()[0]+"-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
	print("FIX_PROBE ",JSON.stringify(result))
	var children := get_tree().root.get_children()
	children.reverse()
	for child in children:
		if child!=self:
			print("CLEANUP ", child.name)
			child.free()
	print("HOST_CLEANUP_DONE")
	print("ENGINE_META_CLEANUP ", Engine.get_meta_list())
	for key in Engine.get_meta_list(): Engine.remove_meta(key)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if passed else 1)
