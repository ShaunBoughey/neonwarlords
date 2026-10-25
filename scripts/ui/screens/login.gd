extends Screen

var name_edit: LineEdit

func _init() -> void:
	show_hud = false

func build() -> void:
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	var c := CenterContainer.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(c)
	var v := UI.vb(18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var t1 := UI.lbl("NEON", 84, UI.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	t1.add_theme_color_override("font_shadow_color", UI.CYAN.darkened(0.3))
	t1.add_theme_constant_override("shadow_offset_y", 0)
	t1.add_theme_constant_override("shadow_outline_size", 18)
	v.add_child(t1)
	var t2 := UI.lbl("WARLORDS", 64, UI.MAGENTA, HORIZONTAL_ALIGNMENT_CENTER)
	t2.add_theme_color_override("font_shadow_color", UI.MAGENTA.darkened(0.3))
	t2.add_theme_constant_override("shadow_outline_size", 16)
	v.add_child(t2)
	v.add_child(UI.lbl("A turn based looter set in a neon dystopian world", 18, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.spacer(false, 0, 20))
	if Game.has_save():
		var p := UI.panel(UI.CYAN, Color(0.04, 0.05, 0.14, 0.9), 10, 18)
		var pv := UI.vb(10)
		pv.add_child(UI.lbl("Welcome back, %s" % Game.S.name, 20, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		pv.add_child(UI.lbl("Player level %d  •  %d Warlords" % [Game.S.player.level, Game.S.roster.size()], 14, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER))
		var b := UI.btn("ENTER THE CITY", func(): _enter(), "primary", 320, 22)
		b.custom_minimum_size.y = 56
		pv.add_child(b)
		pv.add_child(UI.btn("Start a new game", func(): main.confirm("Erase your save and start again?", func():
			Game.reset_save()
			rebuild()), "ghost", 320, 14))
		p.add_child(pv)
		v.add_child(p)
	else:
		var p2 := UI.panel(UI.MAGENTA, Color(0.04, 0.05, 0.14, 0.9), 10, 18)
		var pv2 := UI.vb(10)
		pv2.add_child(UI.lbl("Choose your Warlord name", 18, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		name_edit = LineEdit.new()
		name_edit.placeholder_text = "Name"
		name_edit.text = Content.random_player_name()
		name_edit.max_length = 18
		name_edit.custom_minimum_size = Vector2(320, 44)
		name_edit.add_theme_font_size_override("font_size", 20)
		pv2.add_child(name_edit)
		var b2 := UI.btn("START", func(): _new(), "magenta", 320, 22)
		b2.custom_minimum_size.y = 56
		pv2.add_child(b2)
		p2.add_child(pv2)
		v.add_child(p2)
	if OS.is_debug_build():
		v.add_child(UI.lbl("Prototype build", 14, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER))

func _new() -> void:
	var n := name_edit.text.strip_edges()
	if n == "":
		n = Content.random_player_name()
	Game.new_game(n)
	_enter()

func _enter() -> void:
	main.home()
