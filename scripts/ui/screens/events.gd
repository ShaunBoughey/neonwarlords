extends Screen
## Live events: rotating campaign set, battle pass season, bastion, weekly pit.

func build() -> void:
	header("EVENTS", UI.PURPLE)
	var g := UI.grid(2, 14)
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(g)
	var bp := Game.bp_season_info()
	_card(g, "Battle Pass Season %d" % bp.season, ("%d days left in the season." % bp.days_left) if bp.active else ("Off-season. Next season in %d days." % bp.days_left), UI.YELLOW, func(): main.go("battle_pass"), "ticket")
	_card(g, "Corpo Tower Rotation", "Den 10 drops the %s set today. Rotates daily." % Game.corpo_tower_set(), UI.CYAN, func(): main.go("campaign", {"d": 0, "loc": 9}), "swords")
	var st := int(Game.S.gang.bastion.stage)
	_card(g, "Bastion: Assault on TeraTek", "Stage %d of 3: %s. %d entries left today." % [st, Content.BASTION_STAGES[st - 1].name, int(Game.S.gang.bastion.entries)], UI.RED, func(): main.go("gang"), "shield")
	_card(g, "Pit Weekly Ranking", "Rankings pay out in %s. Brawl: %s, Royal: %s." % [U.dur(U.secs_to_next_week()), Game.pit_tier_row(int(Game.S.pit.brawl.points))[1], Game.pit_tier_row(int(Game.S.pit.royal.points))[1]], UI.MAGENTA, func(): main.go("arena"), "crown")
	_card(g, "Monthly Login Calendar", "Day %d of %d. An Epic Warlord awaits on the final day." % [Game.login_index() + 1, Data.GDD.login.size()], UI.GREEN, func(): main.go("login_rewards"), "gift")
	_card(g, "The Plaza", "Fresh stock every hour. Refreshes in %s." % U.dur(3600.0 - fmod(U.now(), 3600.0)), UI.YELLOW, func(): main.go("plaza"), "tag")

func _card(g: GridContainer, title: String, text: String, col: Color, cb: Callable, icon := "clock") -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 120)
	b.add_theme_stylebox_override("normal", UI._sb(UI.PANEL, col.darkened(0.3), 1, UI.NOTCH, 0))
	b.add_theme_stylebox_override("hover", UI._sb(Color(0.07, 0.24, 0.36, 0.96), col, 2, UI.NOTCH, 0))
	b.add_theme_stylebox_override("pressed", UI._sb(Color(col, 0.2), col, 2, UI.NOTCH, 0))
	var h := UI.hb(16)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 20
	h.offset_right = -18
	var ic := Icon.make(icon, col, 36)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := UI.vb(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.expand(v)
	v.add_child(UI.disp(title, 18, col))
	v.add_child(UI.lbl(text, 15, UI.SOFT, HORIZONTAL_ALIGNMENT_LEFT, true))
	h.add_child(v)
	var chev := Icon.make("right", UI.CYAN, 20)
	chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(chev)
	UI._ignore_mouse(h)
	b.add_child(h)
	b.pressed.connect(cb)
	g.add_child(b)
