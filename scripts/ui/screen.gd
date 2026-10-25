class_name Screen
extends Control
## Base class for code-built screens. Subclasses implement build().
## Hub screens (show_nav) get the bottom navigation; flow screens get a back button only.

var main          # Main.gd
var params: Dictionary = {}
var show_hud := true
var show_nav := false
var bg_mode := "dark"            # "photo" (city art), "dark" (tinted void), "none"
var bg_tint := Color("#0E2238")
var screen_title := ""
var full_bleed := false          # true: ignore the 21:9 menu safe area (battle)
var bleed: Array = []            # full-rect art nodes stretched past the safe area to the window edges
var subtitle := ""
var root: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rebuild()

func rebuild() -> void:
	UI.clear(self)
	bleed = []
	root = UI.vb(12)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 10
	root.offset_bottom = -16
	add_child(root)
	build()
	if main != null:
		main.set_title(screen_title, subtitle)
		main._apply_safe_area()

func build() -> void:
	pass

## Canvas height beyond 16:9 (0 on phones/monitors, 240 at 4:3). Screens that grow into it get
## rebuilt when the window's shape changes.
var _tall_used := -1.0
func tall_extra() -> float:
	_tall_used = max(0.0, get_viewport_rect().size.y - 720.0)
	if not get_viewport().size_changed.is_connected(_on_shape):
		get_viewport().size_changed.connect(_on_shape)
	return _tall_used

func _on_shape() -> void:
	if _tall_used >= 0.0 and absf(max(0.0, get_viewport_rect().size.y - 720.0) - _tall_used) > 1.0:
		rebuild.call_deferred()

## Sets the top-bar title and returns a row inside the screen for right-aligned controls.
func header(text: String, _color := UI.CYAN) -> HBoxContainer:
	screen_title = text
	var h := UI.hb(12)
	h.add_child(UI.spacer())
	root.add_child(h)
	return h

## Segmented control (short lists) or a scrolling strip (long lists).
func tabs(names: Array, current: String, cb: Callable) -> Control:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", UI._sb(UI.PANEL, Color(0, 0, 0, 0), 0, UI.NOTCH, 3))
	var h := UI.hb(3)
	wrap.add_child(h)
	for n in names:
		var on: bool = n == current
		var b := UI.btn(String(n).to_upper(), func(): cb.call(n), "normal", 0, 13)
		b.custom_minimum_size.y = 48
		var sb := UI._sb(UI.CYAN if on else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 8, 14)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", UI._sb(UI.CYAN if on else Color(1, 1, 1, 0.06), Color(0, 0, 0, 0), 0, 8, 14))
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", Color("#05070F") if on else UI.DIM)
		b.add_theme_color_override("font_hover_color", Color("#05070F") if on else UI.TEXT)
		h.add_child(b)
	if names.size() <= 5:
		return wrap
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(wrap)
	return sc

## Vertical category rail (catalogue screens): returns the rail panel.
func rail(groups: Array, current: String, cb: Callable, width := 240) -> PanelContainer:
	var p := UI.panel(UI.LINE, Color(UI.DEEP, 0.92), UI.NOTCH, 0)
	p.custom_minimum_size.x = width
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := UI.vb(0)
	var m := UI.pad(v, 10)
	m.add_theme_constant_override("margin_left", 0)
	m.add_theme_constant_override("margin_right", 0)
	for g in groups:
		if g.get("label", "") != "":
			var gl := UI.cap(g.label, UI.HINT)
			var gm := UI.pad(gl, 0)
			gm.add_theme_constant_override("margin_left", 14)
			gm.add_theme_constant_override("margin_top", 8)
			gm.add_theme_constant_override("margin_bottom", 4)
			v.add_child(gm)
		for it in g.items:
			v.add_child(_rail_row(it, it.id == current, cb))
	var sc := UI.scroll(m)
	p.add_child(sc)
	return p

func _rail_row(it: Dictionary, on: bool, cb: Callable) -> Button:
	var col: Color = it.get("col", UI.CYAN)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 48)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col, 0.22) if on else Color(0, 0, 0, 0)
	sb.border_width_left = 3 if on else 0
	sb.border_color = col
	b.add_theme_stylebox_override("normal", sb)
	var hsb := sb.duplicate()
	hsb.bg_color = Color(col, 0.28) if on else Color(1, 1, 1, 0.05)
	b.add_theme_stylebox_override("hover", hsb)
	b.add_theme_stylebox_override("pressed", hsb)
	var h := UI.hb(8)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -12
	var nm := UI.lbl(it.name, 16, UI.TEXT if on else UI.SOFT)
	UI.expand(nm)
	nm.clip_text = true
	h.add_child(nm)
	if it.get("right", "") != "":
		h.add_child(UI.lbl(it.right, 14, it.get("right_col", UI.DIM)))
	if it.get("dot", false):
		var d := ColorRect.new()
		d.color = UI.RED
		d.custom_minimum_size = Vector2(8, 8)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(d)
	UI._ignore_mouse(h)
	b.add_child(h)
	var id: String = it.id
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call(id))
	return b

func err(msg: String) -> void:
	if msg != "":
		Game.say(msg, UI.RED)
