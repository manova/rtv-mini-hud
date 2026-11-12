extends CanvasLayer
# Independent, mouse-transparent compact row. No native HUD replacement.
const Settings := preload("res://rtv-mini-hud/Settings.gd")
# Native HUD/Permadeath is top-right 100x100 logical pixels on build 25837777.
const PERMADEATH_SIZE := 100.0
const NATIVE_GAP := 16.0
const CELL_WIDTH := 82.0
const BASE_HEIGHT := 82.0
const ORANGE := Color("#e3a45a")
var panel: PanelContainer
var row: HBoxContainer
var _cells: Array[VBoxContainer] = []
var values: Array[Label] = []
var icons: Array[TextureRect] = []
var badges: Array[TextureRect] = []
var shadows: Array[TextureRect] = []
var _textures: Dictionary = {}
var _style: StyleBoxFlat
var _options := {"scale": 1.0, "x": Settings.DEFAULT_X, "y": Settings.DEFAULT_Y, "opacity": 0.42, "orange": false}
var _font: Font

func _init() -> void:
	layer = 5

func _ready() -> void:
	panel = PanelContainer.new()
	panel.name = "MiniHudCompactRow"
	_passthrough(panel)
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.025, 0.028, 0.03, _options.opacity)
	_style.set_corner_radius_all(4)
	_style.content_margin_left = 8
	_style.content_margin_right = 8
	_style.content_margin_top = 10
	_style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", _style)
	add_child(panel)
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	_passthrough(row)
	panel.add_child(row)
	# Reference the game's native font; no proprietary font is redistributed.
	if ResourceLoader.exists("res://Fonts/Lora-Regular.ttf"):
		_font = load("res://Fonts/Lora-Regular.ttf") as Font
	for index in range(3):
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(CELL_WIDTH, 0)
		cell.add_theme_constant_override("separation", 5)
		_passthrough(cell)
		row.add_child(cell)
		_cells.append(cell)
		var icon_area := Control.new()
		icon_area.custom_minimum_size.y = 27
		_passthrough(icon_area)
		cell.add_child(icon_area)
		var shadow := _icon(icon_area, Vector2(30, 1), Vector2(24, 24))
		shadow.modulate = Color(0, 0, 0, 0.7)
		shadows.append(shadow)
		icons.append(_icon(icon_area, Vector2(29, 0), Vector2(24, 24)))
		badges.append(_icon(icon_area, Vector2(58, 14), Vector2(11, 11)))
		var value := Label.new()
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.add_theme_font_size_override("font_size", 19)
		value.add_theme_color_override("font_color", Color("#f3f2ed"))
		value.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		value.add_theme_constant_override("shadow_offset_x", 1)
		value.add_theme_constant_override("shadow_offset_y", 1)
		if _font:
			value.add_theme_font_override("font", _font)
		_passthrough(value)
		cell.add_child(value)
		values.append(value)
	get_viewport().size_changed.connect(_layout)
	_apply_cell_visibility()
	_layout()
	hide()

static func _passthrough(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.focus_mode = Control.FOCUS_NONE

func _icon(parent: Control, at: Vector2, extent: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.anchor_left = 0.5
	icon.anchor_right = 0.5
	icon.position = at - Vector2(CELL_WIDTH / 2, 0)
	icon.size = extent
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_passthrough(icon)
	parent.add_child(icon)
	return icon

func _texture(key: String) -> Texture2D:
	if not _textures.has(key):
		# Raw SVG loading also works inside a VMZ without imported .godot assets.
		var svg := FileAccess.get_file_as_string("res://rtv-mini-hud/assets/" + key + ".svg")
		var image := Image.new()
		if image.load_svg_from_string(svg) != OK:
			return null
		_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]

func configure(options: Dictionary) -> void:
	_options = options
	if not is_node_ready():
		return
	_style.bg_color.a = _options.opacity
	_apply_cell_visibility()
	_layout()

func _apply_cell_visibility() -> void:
	# Keep stable data indices and the clock foundation. Presentation only:
	# hidden cells still receive readings, and no observer or timer is disabled.
	_cells[0].show()
	_cells[1].visible = _options.get("show_trader_timer", true)
	_cells[2].visible = _options.get("show_kill_counter", true)

func clear() -> void:
	for value in values:
		value.text = ""
	hide()

func present(cells: Array) -> void:
	for i in range(3):
		var cell: Dictionary = cells[i]
		values[i].text = cell.value
		icons[i].texture = _texture(cell.icon)
		shadows[i].texture = icons[i].texture
		var tint := ORANGE if i == 1 and _options.orange else Color.WHITE
		icons[i].modulate = tint
		values[i].add_theme_color_override("font_color", tint)
		badges[i].visible = cell.get("status") in ["paused", "inactive", "pending"]
		badges[i].texture = _texture("pause" if cell.get("status") == "paused" else "clock")
		badges[i].modulate = tint
	_layout()
	show()

func _layout() -> void:
	if not is_instance_valid(panel):
		return
	panel.reset_size()
	var visible_count := 1 + int(_options.get("show_trader_timer", true)) + int(_options.get("show_kill_counter", true))
	var extent := Vector2(maxf(CELL_WIDTH * visible_count + 16, panel.get_combined_minimum_size().x),
		maxf(BASE_HEIGHT, panel.get_combined_minimum_size().y))
	var viewport := get_viewport().get_visible_rect().size
	var placement := layout_rect(viewport, extent, _options)
	panel.size = extent
	panel.scale = placement.size / extent
	panel.position = placement.position

static func layout_rect(viewport: Vector2, extent: Vector2, options: Dictionary) -> Rect2:
	var native_default: bool = options.x == Settings.DEFAULT_X and options.y == Settings.DEFAULT_Y
	# Reserve the icon even while hidden: no movement when permadeath activates.
	# Custom MCM positions retain their existing percentage/clamping behavior.
	var usable_width := maxf(0.0, viewport.x - PERMADEATH_SIZE - NATIVE_GAP) if native_default else viewport.x
	var factor := minf(float(options.scale), minf(usable_width / extent.x, viewport.y / extent.y))
	var size := extent * factor
	var available := (viewport - size).max(Vector2.ZERO)
	var at := available * Vector2(options.x, options.y) / 100.0
	if native_default:
		at.x = minf(at.x, maxf(0.0, usable_width - size.x))
	return Rect2(at, size)
