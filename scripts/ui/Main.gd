extends Control
## Root: background, HUD, screen router, modals and toasts.

const SCREENS := {
	"login": "res://scripts/ui/screens/login.gd",
	"city": "res://scripts/ui/screens/city.gd",
	"fight": "res://scripts/ui/screens/fight.gd",
	"campaign": "res://scripts/ui/screens/campaign.gd",
	"hideouts": "res://scripts/ui/screens/hideouts.gd",
	"hideout": "res://scripts/ui/screens/hideouts.gd",
	"sw": "res://scripts/ui/screens/syndicate_wars.gd",
	"arena": "res://scripts/ui/screens/arena.gd",
	"squad": "res://scripts/ui/screens/squad.gd",
	"battle": "res://scripts/ui/screens/battle.gd",
	"armory": "res://scripts/ui/screens/armory.gd",
	"warlord": "res://scripts/ui/screens/warlord.gd",
	"inventory": "res://scripts/ui/screens/inventory.gd",
	"recruit": "res://scripts/ui/screens/recruit.gd",
	"black_market": "res://scripts/ui/screens/black_market.gd",
	"safehouse": "res://scripts/ui/screens/safehouse.gd",
	"plaza": "res://scripts/ui/screens/plaza.gd",
	"gang": "res://scripts/ui/screens/gang.gd",
	"shop": "res://scripts/ui/screens/shop.gd",
	"settings": "res://scripts/ui/screens/settings.gd",
	"inbox": "res://scripts/ui/screens/inbox.gd",
	"account": "res://scripts/ui/screens/account.gd",
	"events": "res://scripts/ui/screens/events.gd",
	"login_rewards": "res://scripts/ui/screens/login_rewards.gd",
	"missions": "res://scripts/ui/screens/missions.gd",
	"battle_pass": "res://scripts/ui/screens/battle_pass.gd",
}

var bg: CityBackground
var hud: Control
var content: Control
var overlay: Control
var toast_box: VBoxContainer
var stack: Array = []   # [[name, params]]
var current: Screen
var hud_labels := {}
var coach: Coach
var _hud_acc := 0.0

func _ready() -> void:
	theme = UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# landscape-only layout: never smaller than 1024x600, and windows narrower than 4:3 (e.g. dragged
	# into portrait) letterbox the 16:9 canvas instead of stretching it taller
	if not OS.has_feature("mobile"):
		get_window().min_size = Vector2i(1024, 600)
	get_viewport().size_changed.connect(_fit_aspect)
	_fit_aspect()
	var base := ColorRect.new()
	base.color = UI.BG
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	bg = CityBackground.new()
	add_child(bg)
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	_build_hud()
	_build_nav()
	coach = Coach.new()
	coach.main = self
	add_child(coach)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	toast_box = UI.vb(6)
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_box.position = Vector2(-220, 72)
	toast_box.custom_minimum_size = Vector2(440, 0)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_box)
	Game.toast.connect(_on_toast)
	Game.changed.connect(_refresh_hud)
	Game.player_leveled.connect(_on_player_leveled)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	go("login", {}, false)

func _process(delta: float) -> void:
	_hud_acc += delta
	if _hud_acc > 1.0:
		_hud_acc = 0.0
		_refresh_hud()

# ================================================================ navigation
## Player-level gate shared by every entry point; returns false (and explains) when locked.
func can_open(name: String) -> bool:
	if Game.feature_ok(name):
		return true
	var info: Array = Data.FEATURE_INFO.get(name, [U.cap(name), ""])
	Game.say("%s unlocks at Player Level %d" % [info[0], Game.feature_level(name)], UI.GOLD)
	return false

func go(name: String, p := {}, push := true) -> void:
	if not can_open(name):
		return
	if push and current != null:
		stack.append([current.get_meta("screen_name"), current.params])
	_show(name, p)

func replace(name: String, p := {}) -> void:
	_show(name, p)

func back() -> void:
	Sfx.play("back")
	close_modal()
	if stack.is_empty():
		_show("city", {})
		return
	var prev: Array = stack.pop_back()
	_show(prev[0], prev[1])

func home() -> void:
	close_modal()
	stack.clear()
	_show("city", {})

## Pop the stack back to the nearest screen with this name (or go home).
func back_to(name: String) -> void:
	close_modal()
	while not stack.is_empty():
		var prev: Array = stack.pop_back()
		if prev[0] == name:
			_show(prev[0], prev[1])
			return
	home()

func _show(name: String, p: Dictionary) -> void:
	if quicknav != null and is_instance_valid(quicknav):
		quicknav.queue_free()
		quicknav = null
	if current != null:
		current.queue_free()
	var scr: Screen = load(SCREENS[name]).new()
	_cur_name = name
	scr.main = self
	scr.params = p
	scr.set_meta("screen_name", name)
	current = scr
	content.add_child(scr)
	var with_nav: bool = scr.show_hud and scr.show_nav
	hud.visible = scr.show_hud
	nav.visible = with_nav
	_refresh_nav(name)
	bg.visible = name != "battle"
	bg.set_mode(scr.bg_mode, scr.bg_tint)
	Sfx.music("battle" if name == "battle" else "city")
	content.offset_top = 64 if scr.show_hud else 0
	content.offset_bottom = -76 if with_nav else 0
	_apply_safe_area()
	set_title(scr.screen_title, scr.subtitle)
	_refresh_hud()

func refresh() -> void:
	if current:
		current.rebuild()

# ================================================================ top bar + bottom navigation
const NAV := [["city", "home", "City"], ["armory", "users", "Warlords"], ["fight", "swords", "Battle"], ["recruit", "case", "Recruit"],
	["plaza", "tag", "Plaza"], ["shop", "cart", "Shop"], ["gang", "shield", "Gang"]]
const NAV_GROUP := {"fight": ["campaign", "hideouts", "hideout", "sw", "arena"], "armory": ["inventory"], "plaza": ["black_market", "safehouse"]}
var nav: Control
var nav_btns := {}
var _cur_name := ""
var hud_title: Label
var hud_sub: Label
var hud_back: Button
var hud_title_box: Control
var hud_profile: Control
var hud_pit: Control
var hud_row: HBoxContainer
var nav_row: HBoxContainer

static func _grad_rect(c0: Color, c1: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, c0)
	g.set_color(1, c1)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	var r := TextureRect.new()
	r.texture = gt
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r

func _build_nav() -> void:
	nav = Control.new()
	nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -76
	nav.add_child(_grad_rect(Color(UI.DEEP, 0.97), UI.BG))
	var line := ColorRect.new()
	line.color = UI.LINE
	line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	line.offset_bottom = 1
	nav.add_child(line)
	var h := UI.hb(0)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nav.add_child(h)
	nav_row = h
	for n in NAV:
		var target: String = n[0]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var glow := _grad_rect(Color(UI.CYAN, 0.24), Color(UI.CYAN, 0.0))
		b.add_child(glow)
		var bar := ColorRect.new()
		bar.color = UI.CYAN
		bar.anchor_left = 0.18
		bar.anchor_right = 0.82
		bar.offset_bottom = 3
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bar)
		var v := UI.vb(4)
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := Icon.make(n[1], UI.DIM, 24)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var lb := UI.cap(n[2], UI.DIM)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lb)
		UI._ignore_mouse(v)
		b.add_child(v)
		var badge := UI.badge(0)
		badge.anchor_left = 0.5
		badge.anchor_right = 0.5
		badge.offset_left = 12
		badge.offset_top = 6
		badge.visible = false
		b.add_child(badge)
		b.pressed.connect(func():
			Sfx.play("click")
			if not can_open(target):
				return
			if target == "city":
				home()
			else:
				stack.clear()
				stack.append(["city", {}])
				_show(target, {}))
		h.add_child(b)
		nav_btns[target] = {"btn": b, "icon": ic, "label": lb, "badge": badge, "glow": glow, "bar": bar, "icon_name": n[1]}
	add_child(nav)

func _refresh_nav(current_name: String) -> void:
	if Game.S.is_empty():
		return
	var badges := {
		"armory": Game.S.roster.filter(func(w): return w.get("new", false)).size(),
		"recruit": int(Game.S.items.contract.uncommon) + int(Game.S.items.contract.rare) + int(Game.S.items.contract.epic) + int(Game.S.items.contract.legendary),
		"gang": int(Game.S.gang.bastion.get("entries", 0)) if not Game.S.gang.is_empty() else 0,
	}
	for k in nav_btns:
		var e: Dictionary = nav_btns[k]
		var active: bool = k == current_name or current_name in NAV_GROUP.get(k, [])
		e.glow.visible = active
		e.bar.visible = active
		var open := Game.feature_ok(k)
		e.icon.icon = e.icon_name if open else "lock"
		e.icon.col = UI.CYAN if active else (UI.DIM if open else UI.HINT)
		e.icon.queue_redraw()
		e.label.add_theme_color_override("font_color", UI.TEXT if active else UI.DIM)
		var n: int = badges.get(k, 0)
		e.badge.visible = n > 0
		e.badge.text = str(n)

func _pill(icon: String, col: Color, key: String, plus: Callable) -> PanelContainer:
	var p := PanelContainer.new()
	var psb := UI._sb(Color(UI.PANEL, 0.95), Color(0, 0, 0, 0), 0, 10, 10)
	psb.content_margin_top = 0
	psb.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", psb)
	p.custom_minimum_size.y = 44
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := UI.hb(8)
	h.add_child(Icon.make(icon, col, 18))
	var l := UI.lbl("", 17, UI.TEXT)
	h.add_child(l)
	hud_labels[key] = l
	if plus.is_valid():
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(44, 44)
		b.add_theme_stylebox_override("normal", UI._sb(UI.GOLD, UI.GOLD, 0, 0, 0))
		b.add_theme_stylebox_override("hover", UI._sb(UI.GOLD.lightened(0.2), UI.GOLD, 0, 0, 0))
		b.add_theme_stylebox_override("pressed", UI._sb(UI.GOLD.darkened(0.2), UI.GOLD, 0, 0, 0))
		var pi := Icon.make("plus", UI.INK, 14)
		pi.position = Vector2(15, 15)
		b.add_child(pi)
		b.pressed.connect(plus)
		h.add_child(b)
	p.add_child(h)
	return p

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud.offset_bottom = 64
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_grad_rect(Color(UI.BG, 0.95), Color(UI.BG, 0.0)))
	var h := UI.hb(14)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 20
	h.offset_right = -20
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(h)
	hud_row = h
	# back + title (flow and hub screens)
	hud_back = UI.btn("", func(): back(), "normal", 44)
	hud_back.custom_minimum_size = Vector2(44, 44)
	hud_back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hud_back.add_theme_stylebox_override("normal", UI._sb(UI.PANEL, Color(0, 0, 0, 0), 0, UI.NOTCH, 0))
	var bi := Icon.make("left", UI.CYAN, 20)
	bi.position = Vector2(12, 12)
	hud_back.add_child(bi)
	h.add_child(hud_back)
	var tv := UI.vb(2)
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_sub = UI.cap("", UI.CYAN)
	tv.add_child(hud_sub)
	hud_title = UI.disp("", 24)
	hud_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hud_title.clip_text = true
	tv.add_child(hud_title)
	var acc := UI.hb(4)
	for w in [[60, 1.0], [10, 0.5], [10, 0.3]]:
		var r := ColorRect.new()
		r.color = Color(UI.CYAN, w[1])
		r.custom_minimum_size = Vector2(w[0], 3)
		acc.add_child(r)
	tv.add_child(acc)
	hud_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hud_sub.clip_text = true
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.custom_minimum_size.x = 120
	hud_title_box = tv
	h.add_child(tv)
	# city profile (replaces back/title on the hub home)
	var prof := UI.hb(12)
	prof.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lvl := HexButton.new()
	lvl.custom_minimum_size = Vector2(50, 46)
	lvl.fill = UI.DEEP
	lvl.fill2 = UI.DEEP
	lvl.border = UI.CYAN
	lvl.glyph_size = 16
	lvl.pressed.connect(func(): go("account"))
	hud_labels.lvl = lvl
	prof.add_child(lvl)
	var pv := UI.vb(4)
	pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hud_labels.name = UI.lbl("", 18, UI.TEXT)
	pv.add_child(hud_labels.name)
	hud_labels.xp = UI.bar(0, 1, UI.CYAN, 6, 150)
	pv.add_child(hud_labels.xp)
	prof.add_child(pv)
	hud_profile = prof
	h.add_child(prof)
	h.add_child(UI.spacer())
	hud_pit = _pill("pitcoin", UI.MAGENTA, "pitCoin", Callable())
	h.add_child(hud_pit)
	h.add_child(_pill("bolt", UI.GOLD, "energy", func(): go("shop", {"sec": "Trinium Market"})))
	h.add_child(_pill("coin", UI.TEXT, "credits", Callable()))
	h.add_child(_pill("diamond", UI.CYAN, "trinium", func(): go("shop", {"sec": "Trinium Vault"})))
	add_child(hud)

## Called by screens (via Screen.rebuild) and the router.
func set_title(t: String, sub := "") -> void:
	if hud_title == null:
		return
	var home_screen := _cur_name == "city"
	hud_back.visible = not home_screen and not (current != null and current.show_nav)
	hud_title_box.visible = not home_screen
	hud_profile.visible = home_screen
	hud_title.text = t.to_upper()
	hud_sub.text = sub.to_upper()
	hud_sub.visible = sub != ""
	hud_pit.visible = _cur_name in ["arena", "black_market", "safehouse"]

func _refresh_hud() -> void:
	if Game.S.is_empty() or hud_labels.is_empty():
		return
	hud_labels.name.text = Game.S.name
	hud_labels.lvl.glyph = str(Game.S.player.level)
	hud_labels.lvl.queue_redraw()
	hud_labels.xp.max_value = max(1, Game.pxp_needed())
	hud_labels.xp.value = Game.S.player.xp
	hud_labels.energy.text = "%d/%d" % [Game.cur("energy"), Data.ENERGY_CAP]
	hud_labels.credits.text = U.fmt(Game.cur("credits"))
	hud_labels.trinium.text = U.fmt(Game.cur("trinium"))
	hud_labels.pitCoin.text = U.fmt(Game.cur("pitCoin"))
	_announce_unlocks()

## "NEW: <feature>" card when the Player Level opens districts (not mid-battle or mid-guide).
## A queued level-up card goes first; several unlocks at once share one card, one row each.
func _announce_unlocks() -> void:
	if _cur_name in ["battle", "login", "squad"] or overlay.get_child_count() > 0:
		return
	if coach != null and coach.active():
		return
	if not _levelups.is_empty():
		_show_levelup(_levelups.pop_front())
		return
	var fresh := Game.take_new_unlocks()
	if fresh.is_empty():
		return
	if _cur_name in ["city", "fight"]:
		refresh()
	Sfx.play("levelup")
	var dim_ref := []
	var go_to := func(id: String) -> void:
		_close(dim_ref[0])
		stack.clear()
		stack.append(["city", {}])
		_show(id, {})
	var v := UI.vb(12)
	for i in fresh.size():
		var id: String = fresh[i]
		var info: Array = Data.FEATURE_INFO[id]
		var district: bool = id in ["hideouts", "sw", "arena", "black_market", "plaza", "safehouse", "gang"]
		if fresh.size() == 1:
			v.add_child(UI.tag("New district unlocked" if district else "New feature unlocked", UI.GOLD))
			v.add_child(UI.disp(info[0], 30))
			v.add_child(UI.lbl(info[1], 16, UI.SOFT, HORIZONTAL_ALIGNMENT_LEFT, true))
			continue
		var row := UI.hb(12)
		var tv := UI.vb(2)
		UI.expand(tv)
		tv.add_child(UI.tag("District" if district else "Feature", UI.GOLD))
		tv.add_child(UI.disp(info[0], 20))
		tv.add_child(UI.lbl(info[1], 15, UI.SOFT, HORIZONTAL_ALIGNMENT_LEFT, true))
		row.add_child(tv)
		var gb := UI.btn("GO", go_to.bind(id), "gold" if i == 0 else "primary", 100)
		gb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(gb)
		v.add_child(row)
	var h := UI.hb(10)
	h.add_child(UI.spacer())
	h.add_child(UI.btn("LATER", func(): _close(dim_ref[0]), "ghost", 120))
	if fresh.size() == 1:
		h.add_child(UI.btn("GO", go_to.bind(String(fresh[0])), "gold", 140))
	v.add_child(h)
	dim_ref.append(modal("Unlocked", v, fresh.size() > 2))
	refresh_nav()

# ================================================================ level-up card
var _levelups: Array = []   # [{level, rewards, mail}]

func _on_player_leveled(level: int, rewards: Array) -> void:
	var mail = Game.S.inbox[0] if not Game.S.inbox.is_empty() else null
	_levelups.append({"level": level, "rewards": rewards, "mail": mail})
	if _levelups.size() > 3:
		_levelups.pop_front()   # a burst of levels: keep the latest few
	_announce_unlocks.call_deferred()

func _show_levelup(e: Dictionary) -> void:
	Sfx.play("levelup")
	var maxed: bool = Game.S.player.get("maxed", false) and e.level == int(Game.S.player.level)
	var v := UI.vb(12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := UI.disp("Max player level" if maxed else "Player level %d" % e.level, 34, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var en := UI.lbl("Energy refilled", 17, UI.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(en)
	var rewards: Array = e.rewards
	if not rewards.is_empty():
		var chips := UI.reward_chips(rewards, 15)
		chips.alignment = FlowContainer.ALIGNMENT_CENTER
		v.add_child(chips)
	var dim_ref := []
	var h := UI.hb(10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var mail = e.mail
	if mail != null and not mail.claimed:
		h.add_child(UI.btn("LATER", func(): _close(dim_ref[0]), "ghost", 120))
		h.add_child(UI.btn("CLAIM", func():
			_close(dim_ref[0])
			show_rewards("Player level %d" % e.level, Game.claim_mail(mail)), "gold", 160))
	else:
		h.add_child(UI.btn("OK", func(): _close(dim_ref[0]), "gold", 160))
	dim_ref.append(modal("Level up", v, false, true, h))

# ================================================================ safe area (notches, rounded corners)
const MENU_MAX_W := 1720.0   # 21:9 (3440x1440) at the 720-high canvas

func _apply_safe_area() -> void:
	if hud == null or nav == null:
		return
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var l := 0.0
	var r := 0.0
	if win.x > 0 and safe.size.x > 0 and DisplayServer.screen_get_size() == DisplayServer.window_get_size():
		var k: float = get_viewport_rect().size.x / win.x
		l = max(0.0, safe.position.x) * k
		r = max(0.0, win.x - safe.end.x) * k
	for c in [hud, nav, content]:
		c.offset_left = l
		c.offset_right = -r
	# ultra-wide (past 21:9): bars and backgrounds stay full-bleed, but menu content, the HUD clusters
	# and the nav items sit in a centred safe area no wider than a 21:9 canvas
	var extra: float = max(0.0, (get_viewport_rect().size.x - l - r - MENU_MAX_W) / 2.0)
	if hud_row != null:
		hud_row.offset_left = 20 + extra
		hud_row.offset_right = -20 - extra
	if nav_row != null:
		nav_row.offset_left = extra
		nav_row.offset_right = -extra
	if current != null and not current.full_bleed:
		content.offset_left = l + extra
		content.offset_right = -r - extra
		for n in current.bleed:
			if is_instance_valid(n):
				n.offset_left = -extra
				n.offset_right = extra

func refresh_nav() -> void:
	_refresh_nav(_cur_name)

# ================================================================ quick navigation
const QUICKNAV := [["QNCityCentreButton", "city"], ["QNCampaignButton", "campaign"], ["QNHideoutsButton", "hideouts"], ["QNSyndicatesButton", "sw"],
	["QNThePitButton", "arena"], ["QNBastionsButton", "gang"], ["QNCrewsButton", "gang"], ["QNBlackMarketButton", "black_market"], ["QNShopButton", "shop"]]
var quicknav: Control

func _toggle_quicknav() -> void:
	if quicknav != null and is_instance_valid(quicknav):
		quicknav.queue_free()
		quicknav = null
		return
	quicknav = UI.panel(UI.MAGENTA.darkened(0.2), Color(0.05, 0.02, 0.1, 0.92), 8, 6)
	var row := UI.hb(4)
	quicknav.add_child(row)
	for q in QUICKNAV:
		var target: String = q[1]
		var b := Art.button("QuickNavigationBarG/QuickNavigationButtonsG/" + q[0], func():
			quicknav.queue_free()
			quicknav = null
			if target == "city":
				home()
			else:
				go(target), Vector2.ZERO, 0.75)
		b.custom_minimum_size = Vector2(42, 134)
		row.add_child(b)
	quicknav.position = Vector2(300, 58)
	add_child(quicknav)

# ================================================================ modals
func modal(title_text: String, body: Control, wide := false, closable := true, footer: Control = null) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var p := UI.panel(UI.LINE, Color(UI.DEEP, 0.98), UI.NOTCH, 20)
	var w := 960 if wide else 580
	p.custom_minimum_size = Vector2(w, 0)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	center.add_child(p)
	var v := UI.vb(10)
	p.add_child(v)
	var h := UI.hb()
	h.add_child(UI.title(title_text))
	h.add_child(UI.spacer())
	if closable:
		var x := UI.btn("", func(): _close(dim), "ghost", 44)
		x.custom_minimum_size = Vector2(44, 44)
		var xi := Icon.make("plus", UI.SOFT, 18)
		xi.position = Vector2(13, 13)
		xi.pivot_offset = Vector2(9, 9)
		xi.rotation_degrees = 45
		x.add_child(xi)
		h.add_child(x)
	v.add_child(h)
	var max_h := get_viewport_rect().size.y - 150 - (70 if footer != null else 0)
	var sc := UI.scroll(body)
	sc.custom_minimum_size = Vector2(w - 40, 60)
	v.add_child(sc)
	if footer != null:
		v.add_child(footer)
	_fit_scroll.call_deferred(sc, body, max_h)
	p.modulate.a = 0.0
	p.create_tween().tween_property(p, "modulate:a", 1.0, 0.15)
	return dim

func _fit_scroll(sc: ScrollContainer, body: Control, max_h: float) -> void:
	if not is_instance_valid(sc):
		return
	await get_tree().process_frame
	if not is_instance_valid(sc):
		return
	sc.custom_minimum_size.y = min(max_h, body.get_combined_minimum_size().y + 4)

func _close(dim: Control) -> void:
	if is_instance_valid(dim):
		dim.queue_free()

func close_modal() -> void:
	for c in overlay.get_children():
		c.queue_free()

func confirm(text: String, cb: Callable, ok_text := "Confirm") -> void:
	var v := UI.vb(14)
	v.add_child(UI.lbl(text, 16, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var h := UI.hb()
	h.add_child(UI.spacer())
	var dim_ref := []
	h.add_child(UI.btn("Cancel", func(): _close(dim_ref[0]), "ghost", 120))
	h.add_child(UI.btn(ok_text, func():
		_close(dim_ref[0])
		cb.call(), "primary", 140))
	v.add_child(h)
	dim_ref.append(modal("Confirm", v))

func show_rewards(title_text: String, list: Array, after := Callable()) -> void:
	if list.is_empty():
		return
	Sfx.play("reward")
	var v := UI.vb(12)
	var f := UI.flow(10)
	f.alignment = FlowContainer.ALIGNMENT_CENTER
	var i := 0
	for r in list:
		var tile := UI.reward_tile(r, 84)
		tile.modulate.a = 0.0
		f.add_child(tile)
		var tw := tile.create_tween()   # bound to the tile so closing the modal early is clean
		tw.tween_interval(0.05 * i)
		tw.tween_property(tile, "modulate:a", 1.0, 0.2)
		i += 1
	v.add_child(f)
	var dim_ref := []
	var h := UI.hb()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UI.btn("COLLECT", func():
		_close(dim_ref[0])
		if after.is_valid(): after.call(), "gold", 200, 18))
	dim_ref.append(modal(title_text, v, list.size() > 5, true, h))

# ================================================================ toasts
func _on_toast(text: String, color: Color) -> void:
	var p := UI.panel(color, Color(0.03, 0.04, 0.1, 0.95), 8, 10)
	var l := UI.lbl(text, 15, color, HORIZONTAL_ALIGNMENT_CENTER)
	p.add_child(l)
	toast_box.add_child(p)
	var tw := p.create_tween()   # bound to the toast: old toasts are trimmed below while their fade is pending
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
	while toast_box.get_child_count() > 4:
		toast_box.get_child(0).queue_free()
		toast_box.remove_child(toast_box.get_child(0))

# ================================================================ encounter flow
func start_encounter(enc: Dictionary) -> void:
	go("squad", {"enc": enc})

func _fit_aspect() -> void:
	var w := get_window()
	var a: float = float(w.size.x) / maxf(1.0, float(w.size.y))
	var want := Window.CONTENT_SCALE_ASPECT_KEEP if a < 1.3 else Window.CONTENT_SCALE_ASPECT_EXPAND
	if w.content_scale_aspect != want:
		w.content_scale_aspect = want
