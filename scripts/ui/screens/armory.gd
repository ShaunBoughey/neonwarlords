extends Screen
## Armory: the Warlord roster with sorting and filters.

func build() -> void:
	show_nav = true
	var sort: String = params.get("sort", "Power")
	var rar: String = params.get("rar", "all")
	var syn: String = params.get("syn", "all")
	var al: String = params.get("al", "all")
	var cls: String = params.get("cls", "all")
	screen_title = "Warlords"
	subtitle = "%d in your roster" % Game.S.roster.size()
	var items: Array = [{"id": "all", "name": "All syndicates", "right": str(Game.S.roster.size())}]
	for k in Data.SYNDICATES:
		var n: int = Game.S.roster.filter(func(w): return Game.tpl(w).syn == k).size()
		items.append({"id": k, "name": Data.SYNDICATES[k].name, "right": str(n), "col": Data.SYNDICATES[k].color})
	var rl := rail([{"label": "Syndicate", "items": items}], syn, func(id):
		params.syn = id
		rebuild(), 240)
	rl.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	rl.offset_left = 20
	rl.offset_right = 260
	rl.offset_top = 10
	rl.offset_bottom = -16
	add_child(rl)
	var body := UI.vb(12)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 280
	body.offset_right = -20
	body.offset_top = 10
	body.offset_bottom = -16
	add_child(body)
	var f := UI.hb(8)
	for r in ["all"] + Data.RARITIES:
		var col: Color = UI.CYAN if r == "all" else Data.RARITY_COLOR[r]
		var on: bool = r == rar
		var b := UI.btn("All" if r == "all" else U.cap(r), func():
			params.rar = r
			rebuild(), "normal", 0, 13)
		b.custom_minimum_size.y = 38
		b.add_theme_stylebox_override("normal", UI._sb(Color(col, 0.22) if on else Color(UI.DEEP, 0.85), col if on else UI.LINE, 2 if on else 1, 8, 12))
		b.add_theme_color_override("font_color", UI.TEXT if on else col)
		f.add_child(b)
	f.add_child(UI.spacer())
	f.add_child(UI.cap("Sort"))
	f.add_child(tabs(["Power", "Level", "Rank", "Rep", "Rarity", "Name"], sort, func(n):
		params.sort = n
		rebuild()))
	body.add_child(f)
	# alignment and class filters
	var f2 := UI.hb(8)
	f2.add_child(UI.cap("Alignment"))
	for a in ["all"] + Data.ALIGNMENTS:
		f2.add_child(_filter_btn(a, a == al, UI.CYAN if a == "all" else Data.ALIGN_COLOR[a], func():
			params.al = a
			rebuild(), "" if a == "all" else a))
	f2.add_child(UI.spacer())
	f2.add_child(UI.cap("Class"))
	for c in ["all"] + Data.CLASS_INFO.keys():
		f2.add_child(_filter_btn(c, c == cls, UI.CYAN, func():
			params.cls = c
			rebuild(), ""))
	body.add_child(f2)
	var list: Array = Game.S.roster.filter(func(w):
		var t := Game.tpl(w)
		return (rar == "all" or t.rarity == rar) and (syn == "all" or t.syn == syn) 			and (al == "all" or t.align == al) and (cls == "all" or t.cls == cls))
	match sort:
		"Power": list.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
		"Level": list.sort_custom(func(a, b): return a.level * 10 + a.rank > b.level * 10 + b.rank)
		"Rank": list.sort_custom(func(a, b): return a.rank * 100 + a.level > b.rank * 100 + b.level)
		"Rep": list.sort_custom(func(a, b): return a.rep * 100 + a.rank > b.rep * 100 + b.rank)
		"Rarity": list.sort_custom(func(a, b): return Data.rarity_idx(Game.tpl(a).rarity) > Data.rarity_idx(Game.tpl(b).rarity))
		"Name": list.sort_custom(func(a, b): return Game.tpl(a).name < Game.tpl(b).name)
	var g := UI.flow(10)
	for w in list:
		var uid: String = w.uid
		var card := UI.warlord_card(w, func(): main.go("warlord", {"uid": uid}))
		if g.get_child_count() == 0:
			card.set_meta("coach", "warlord_card")
		g.add_child(card)
	if list.is_empty():
		g.add_child(UI.lbl("No Warlords match these filters.", 16, UI.DIM))
	var seen_any := false
	for w in Game.S.roster:
		if w.get("new", false):
			w.new = false
			seen_any = true
	if seen_any:
		Game.mark()
	body.add_child(UI.scroll(g))
	var foot := UI.hb(10)
	foot.add_child(UI.lbl("%d shown" % list.size(), 14, UI.DIM))
	foot.add_child(UI.spacer())
	foot.add_child(UI.btn("INVENTORY", func(): main.go("inventory"), "primary", 160, 14))
	foot.add_child(UI.btn("RECRUIT", func(): main.go("recruit"), "gold", 160, 15))
	body.add_child(foot)

func _filter_btn(id: String, on: bool, col: Color, cb: Callable, icon: String) -> Button:
	var text: String = "All" if id == "all" else (Data.CLASS_INFO[id].name if Data.CLASS_INFO.has(id) else U.cap(id))
	var b := UI.btn(text, cb, "normal", 0, 13)
	b.custom_minimum_size.y = 34
	b.add_theme_stylebox_override("normal", UI._sb(Color(col, 0.22) if on else Color(UI.DEEP, 0.85), col if on else UI.LINE, 2 if on else 1, 8, 12))
	b.add_theme_color_override("font_color", UI.TEXT if on else col)
	if icon != "":
		b.icon = null
		var ic := Icon.make(icon, col, 18)
		b.add_child(ic)
		b.add_theme_constant_override("h_separation", 0)
		b.text = "     " + text
		ic.position = Vector2(10, 8)
		b.tooltip_text = UI.ALIGN_INFO[icon]
	return b
