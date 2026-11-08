extends Node
const Model := preload("res://rtv-mini-hud/Model.gd")
const Reader := preload("res://rtv-mini-hud/TimerReader.gd")
const HudPanel := preload("res://rtv-mini-hud/Panel.gd")
const ClockReader := preload("res://rtv-mini-hud/ClockReader.gd")
const WatchReader := preload("res://rtv-mini-hud/WatchReader.gd")
const KillObserver := preload("res://rtv-mini-hud/KillObserver.gd")
const RefreshGate := preload("res://rtv-mini-hud/RefreshGate.gd")
const Settings := preload("res://rtv-mini-hud/Settings.gd")

var _model := Model.new()
var _kills := KillObserver.new()
var _refresh := RefreshGate.new()
var _clock := ClockReader.new()
var _clock_state := ClockReader.unavailable()
var _panel: CanvasLayer
var _game_data: Resource
var _scene_id := 0
var _show_without_watch := false
var _clock_allowed := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = HudPanel.new()
	add_child(_panel)
	if ResourceLoader.exists("res://Resources/GameData.tres"):
		_game_data = load("res://Resources/GameData.tres")
	_kills.sync_state(_game_data)
	# Framework pre/post observers never replace or invoke damage themselves.
	if Engine.has_meta("RTVModLib"):
		var lib = Engine.get_meta("RTVModLib")
		if Reader.property(lib, &"_is_ready") == true:
			_on_lib_ready()
		elif is_instance_valid(lib) and lib.has_signal("frameworks_ready"):
			lib.frameworks_ready.connect(_on_lib_ready, CONNECT_ONE_SHOT)
	# Defer configuration so earlier MCM autoloads can complete initialization.
	Settings.install.call_deferred(self)

func _on_lib_ready() -> void:
	if Engine.has_meta("RTVModLib"):
		_kills.install(self, Engine.get_meta("RTVModLib"))
		if not _kills.reason.is_empty():
			print("[Mini HUD] Kill counter unavailable: " + _kills.reason)

func _exit_tree() -> void:
	_kills.uninstall()

func apply_config(config: ConfigFile) -> void:
	var state := Settings.normalized(config)
	_model.enabled = state.enabled
	_model.set_display_mode(state.display_mode)
	_kills.cumulative = state.cumulative_kills
	_kills.trace.configure(state.attribution_trace)
	if _show_without_watch != state.show_without_watch:
		_clock.reset()
	_show_without_watch = state.show_without_watch
	_panel.configure(state.layout)
	if not _model.enabled:
		_model.reset()
	if not InputMap.has_action(Settings.ACTION):
		InputMap.add_action(Settings.ACTION)
	InputMap.action_erase_events(Settings.ACTION)
	InputMap.action_add_event(Settings.ACTION, state.event)
	_refresh.reset()

func _sync_scene() -> void:
	var scene := get_tree().current_scene
	var identity := scene.get_instance_id() if is_instance_valid(scene) else 0
	if identity != _scene_id:
		_scene_id = identity
		# Travel retains the user choice; scene-bound observations never survive.
		_panel.hide()
		_panel.clear()
		_clock.reset()
		_clock_state = ClockReader.unavailable()
		_clock_allowed = false
		_refresh.reset()

func _context() -> Dictionary:
	return Reader.context(_game_data, get_tree().current_scene, get_tree())

func _unhandled_input(event: InputEvent) -> void:
	if _model.display_mode != Model.MODE_TOGGLE:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	if not Settings.shortcut_pressed(event):
		return
	_sync_scene()
	if _model.toggle(_context()):
		get_viewport().set_input_as_handled()
		_refresh.reset()
		_render(0.0)

func _process(delta: float) -> void:
	_sync_scene()
	_render(delta)

func _render(_delta: float, now_usec: int = -1) -> void:
	var context := _context()
	# Synchronize even while hidden, disabled, paused or suppressed.
	_kills.sync_state(_game_data)
	var scene := get_tree().current_scene
	var clock_allowed := _model.allowed(context) and (_show_without_watch or WatchReader.equipped(scene))
	if clock_allowed != _clock_allowed:
		_clock_allowed = clock_allowed
		_clock.reset()
		_refresh.reset()
	_clock_state = _clock.read(scene, _game_data,
		get_node_or_null("/root/Simulation"), clock_allowed)
	if Reader.property(_game_data, &"menu") == true or Reader.property(_game_data, &"isDead") == true:
		_model.reset()
	if not _model.visible_in(context):
		_panel.hide()
		_refresh.reset()
		return
	var now := Time.get_ticks_usec() if now_usec < 0 else now_usec
	if _refresh.due(now):
		_panel.present([_clock_state,
			Model.trader_cell(Reader.read(get_tree(), get_tree().current_scene)), _kills.read()])
